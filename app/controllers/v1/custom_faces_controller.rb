# frozen_string_literal: true

require 'base64'
require 'date'
require 'securerandom'
require 'sinatra/base'
require 'sinatra/multi_route'

require_relative '../../helpers/hash'
require_relative '../../models/custom_face'
require_relative '../../models/random_custom_face'
require_relative '../../models/mashup_custom_face'

# Defines the faces endpoints
class CustomFacesController < Sinatra::Base
  register Sinatra::MultiRoute

  before do
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => %w[GET POST]
  end

  VALID_PARAMS = %i[
    twemoji_version
  ].freeze

  BUILDING_PARAMS = [
    CustomFace::DEFAULT_FEATURE_STACKING_ORDER,
    :background_color,
    :file_format,
    :filename,
    :order,
    :output,
    :padding,
    :renderer,
    :size
  ].flatten.freeze

  BASE_ENDPOINT = '/v1/custom_faces'

  get "#{BASE_ENDPOINT}/random" do
    validate(BUILDING_PARAMS)
    face = RandomCustomFace.new(params)
    process_valid_request(face, face_url(face, CustomFace::DEFAULT_FEATURE_STACKING_ORDER))
  rescue StandardError => e
    handle_error(e)
  end

  get "#{BASE_ENDPOINT}/mashup" do
    endpoint_specific_params = %i[
      amount
      emojis
      use_every_feature
    ]

    validate([BUILDING_PARAMS, endpoint_specific_params].flatten.freeze)
    face = MashupCustomFace.new(params)

    process_valid_request(face, face_url(face, endpoint_specific_params))
  rescue StandardError => e
    handle_error(e)
  end

  get "#{BASE_ENDPOINT}/:emoji_id" do
    endpoint_specific_params = %i[
      emoji_id
    ]

    validate([BUILDING_PARAMS, endpoint_specific_params].flatten.freeze)
    process_valid_request(CustomFace.new(params))
  rescue StandardError => e
    handle_error(e)
  end

  private

  def handle_error(error)
    content_type 'application/json'
    LOGGER.error(error.message)

    response = {
      success: false,
      error: error.message
    }

    status_code = error.respond_to?(:status_code) ? error.status_code : 500

    error status_code, response.to_json
  end

  def validate_output
    unless [nil, '', 'json', 'image', 'download'].include?(@params[:output])
      message = "Output not supported: #{@params[:output]} | Valid file formats: json, image, download"
      error 405, { error: message }.to_json
    end
    @output = params[:output].presence || 'json'
  end

  def validate_file_format
    unless [nil, '', 'svg', 'png'].include?(@params[:file_format])
      message = "File format not supported: #{@params[:file_format]} | Valid file formats: svg, png"
      error 405, { error: message }.to_json
    end
    @file_format = @params[:file_format].presence || 'svg'
  end

  def validate(endpoint_specific_params = nil)
    validate_output
    validate_file_format

    @twemoji_version = Twemoji.validate_version(params[:twemoji_version])
    params[:twemoji_version] = @twemoji_version

    valid_params = [
      VALID_PARAMS,
      endpoint_specific_params
    ].flatten.freeze

    validate_params(@params.symbolize_keys, valid_params)
  end

  def process_valid_request(face, url = nil)
    resource = get_resource_in_file_format(face)

    case @output
    when 'json'
      url.nil? ? json(resource, face.description) : json(resource, face.description, url)
    when 'image', 'download'
      resource
    else
      message = "Output not supported: #{@output} | Valid file formats: json, image, download"
      error 405, { error: message }.to_json
    end
  end

  def validate_params(params, valid_params = VALID_PARAMS)
    params.select { |key, _| valid_params.include?(key) }

    # Add time parameter to track request
    params[:time] = Time.now.getutc.to_i
  end

  def set_content_disposition(resource, file_extension)
    return unless @output == 'download'

    filename = @params[:filename].presence || resource.unique_string
    full_filename = "#{filename}.#{file_extension}"

    # Good explanation on this: https://stackoverflow.com/a/20509354/5988852
    headers['Content-Disposition'] = "attachment;filename=\"#{full_filename}\""
  end

  def svg(resource)
    unless @output == 'json'
      content_type 'image/svg+xml'
      set_content_disposition(resource, __method__.to_s)
    end

    @output == 'download' ? resource.svg : resource.xml
  end

  def png(resource)
    renderer = @params[:renderer].presence || @output == 'image' ? 'canvg' : 'imagemagick'
    nonce = SecureRandom.hex(32) + DateTime.now.new_offset(0).strftime('%s')

    if renderer == 'canvg'
      puts 'adding Content-Security-Policy'
      headers['Content-Security-Policy'] =
        "script-src 'nonce-#{nonce}'; frame-ancestors customtwemoji.com"
    end

    if @output == 'json'
      content_type 'text/html' if renderer == 'canvg'
      return Base64.encode64(resource.png(renderer, nonce)).gsub("\n", '')
    end

    content_type renderer == 'canvg' ? 'text/html' : 'image/png'
    set_content_disposition(resource, __method__.to_s)

    resource.png(renderer, nonce)
  end

  def get_resource_in_file_format(resource)
    case @file_format
    when nil, 'svg'
      svg(resource)
    when 'png'
      png(resource)
    end
  end

  def face_url(face, exclude_params)
    url = "https://#{@env['HTTP_HOST']}#{BASE_ENDPOINT}/#{face.url}"

    request.params.each do |key, value|
      next if exclude_params.include?(key.to_sym)

      feature_hash = { key => value }
      url =
        "#{url}#{'&' unless url.end_with?('?')}#{URI.encode_www_form(feature_hash)}"
    end

    url
  end

  def json(data, description, links_self = request.url)
    content_type 'application/json'

    {
      success: true,
      data: {
        output: data,
        description:
      },
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
