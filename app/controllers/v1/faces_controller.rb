# frozen_string_literal: true

require 'base64'
require 'date'
require 'securerandom'
require 'sinatra/base'
require 'sinatra/multi_route'

require_relative '../../helpers/error'
require_relative '../../helpers/hash'
require_relative '../../models/custom_face'
require_relative '../../models/random_custom_face'
require_relative '../../models/mashup_custom_face'
require_relative '../../models/twemoji/twemoji'

# Defines the faces endpoints
class FacesController < Sinatra::Base
  register Sinatra::MultiRoute

  before do
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => '%w[GET]'
  end

  VALID_PARAMS = %i[
    index_by
    twemoji_version
  ].freeze

  BASE_ENDPOINT = '/v1/faces'

  get BASE_ENDPOINT do
    validate

    faces = Face.all(@twemoji_version)
    apply_filters(params, faces)

    json(faces)
  rescue StandardError => e
    handle_error(e)
  end

  get "#{BASE_ENDPOINT}/random" do
    validate

    face = Face.random(@twemoji_version)
    apply_filters(params, face)

    url = "https://#{@env['HTTP_HOST']}#{BASE_ENDPOINT}/#{face.keys[0]}"
    json(face, url)
  rescue StandardError => e
    handle_error(e)
  end

  get "#{BASE_ENDPOINT}/", "#{BASE_ENDPOINT}/:emoji_id" do
    validate
    @emoji_id = params[:emoji_id]

    message = "Parameter 'emoji_id' is required"
    raise CustomTwemojiApiError.new(400), message if @emoji_id.nil?

    face = {
      @emoji_id.to_s => Face.find_with_layers(@twemoji_version, @emoji_id)
    }
    apply_filters(params, face)

    json(face)
  rescue StandardError => e
    handle_error(e)
  end

  private

  def handle_error(error)
    LOGGER.error(error.message)

    response = {
      success: false,
      error: error.message
    }
    status_code = error.respond_to?(:status_code) ? error.status_code : 500

    error status_code, response.to_json
  end

  def initialize_params(params)
    params.select { |key, _| VALID_PARAMS.include?(key) }

    # Add time parameter to track request
    params[:time] = Time.now.getutc.to_i
  end

  def validate
    content_type 'application/json'
    initialize_params(params)

    @twemoji_version = Twemoji.validate_version(params[:twemoji_version])

    @index_by = params[:index_by]

    valid_values = %w[features layers].freeze
    message = "Invalid 'index_by' parameter: #{@index_by} | " \
              "Valid values: #{valid_values.join(', ')}"

    raise CustomTwemojiApiError.new(400), message unless valid_values.include?(@index_by) || @index_by.nil?
  end

  def filter_by_features(features, faces)
    return if features.nil?

    features = features.split(',')
    return if features.empty?

    faces.transform_values! do |value|
      {
        'glyph' => value['glyph'],
        'layers' => value['layers'].select { |_key2, value2| features.include?(value2) }
      }
    end
  end

  def filter_by_layers(layers, faces)
    return if layers.nil?

    # rubocop:disable Style/RescueModifier
    layers = layers.split(',').select { |value| Integer(value) rescue nil }.map(&:to_i)
    # rubocop:enable Style/RescueModifier
    return if layers.empty?

    faces.transform_values! do |value|
      {
        'glyph' => value['glyph'],
        'layers' => value['layers'].select { |key2, _value2| layers.include?(key2) }
      }
    end
  end

  def apply_filters(params, faces)
    filter_by_features(params[:include_features], faces)
    filter_by_layers(params[:include_layers], faces)

    unless params[:include_empty_layers] == 'true'
      faces.reject! { |_, value| value['layers'].empty? }
    end

    return unless params[:include_glyph] == 'false'

    faces.each_value do |value|
      value.delete('glyph')
    end
  end

  def index_by(data)
    return data unless @index_by == 'features'

    data.each do |key, value|
      data[key]['layers'] = Face.layers_to_features(value['layers'])
    end
  end

  def json(data, links_self = request.url)
    {
      success: true,
      data: index_by(data),
      links: {
        self: links_self
      },
      license: {
        name: 'CC-BY 4.0',
        url: 'https://creativecommons.org/licenses/by/4.0'
      }
    }.to_json
  end

  run! if app_file == $PROGRAM_NAME
end
