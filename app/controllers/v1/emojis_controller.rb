# frozen_string_literal: true

require 'base64'
require 'json'
require 'sinatra/base'
require 'sinatra/multi_route'

require_relative '../../helpers/hash'
require_relative '../../models/custom_layers_emoji'

# Defines the emojis endpoints
class EmojisController < Sinatra::Base
  register Sinatra::MultiRoute

  VALID_PARAMS = %i[
    absolute_paths
    background_color
    file_format
    filename
    order
    output
    padding
    renderer
    size
    time
    twemoji_version
  ].freeze

  before do
    @request_payload = JSON.parse(request.body.read)
  end

  post '/v1/emojis', '/v1/emojis/' do
    validate
    process_valid_request(CustomLayersEmoji.new(params))
  rescue StandardError => e
    runtime_error(e)
  end

  # get '/v1/emojis/:emoji_id/layers' do
  #   json(Face.all(params[:twemoji_version]))
  # end

  # get '/v1/emojis/random', '/v1/emojis/random/' do
  #   validate
  #   face = RandomCustomFace.new(params)
  #   process_valid_request(face, face_url(face))
  # rescue StandardError => e
  #   runtime_error(e)
  # end

  not_found do
    content_type 'application/json'
    message =
      "Endpoint not found: #{request.request_method} #{request.path_info}"\
      ' | Valid endpoints: POST /emojis, GET /emojis/{emoji_id}, ' \
      'GET/emojis/{emoji_id}/layers, GET /emojis/random'
    error 404, { error: message }.to_json
  end

  private

  def runtime_error(error)
    LOGGER.error(error.message)
    content_type 'application/json'
    response = {
      success: false,
      error: error.message
    }
    error 500, response.to_json
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

  def validate
    validate_output
    validate_file_format

    raise 'No request body detected' if @request_payload.empty?

    params[:body] = @request_payload
  end

  def process_valid_request(layers_emoji)
    resource = get_resource(layers_emoji)

    case @output
    when 'json'
      json(resource)
    when 'image', 'download'
      resource
    else
      message = "Output not supported: #{@output} | Valid file formats: json, image, download"
      error 405, { error: message }.to_json
    end
  end

  def symbolize_params
    params.map do |(k, v)|
      [k.to_sym, v]
    end.to_h
  end

  def validate_params(params)
    # Add time parameter to track request
    params[:time] = Time.now.getutc.to_i

    params.select { |key, _| VALID_PARAMS.include?(key) }
  end

  def set_content_disposition(resource, file_extension)
    return unless @output == 'download'

    filename = @params[:filename].presence || resource.to_s
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

    if @output == 'json'
      content_type 'text/html' if renderer == 'canvg'
      return Base64.encode64(resource.png(renderer)).gsub(/\n/, '')
    end

    content_type renderer == 'canvg' ? 'text/html' : 'image/png'
    set_content_disposition(resource, __method__.to_s)

    resource.png(renderer)
  end

  def get_resource(resource)
    case @file_format
    when nil, 'svg'
      svg(resource)
    when 'png'
      png(resource)
    end
  end

  def json(resource)
    content_type 'application/json'
    {
      success: true,
      resource: resource,
      license: {
        name: 'CC-BY 4.0',
        url: 'https://creativecommons.org/licenses/by/4.0'
      }
    }.to_json
  end

  run! if app_file == $PROGRAM_NAME
end
