# frozen_string_literal: true

require 'base64'
require 'sinatra/base'
require 'sinatra/multi_route'

require_relative '../../helpers/hash'
require_relative '../../models/custom_face'
require_relative '../../models/random_custom_face'

# Defines the faces endpoints
class FacesController < Sinatra::Base
  register Sinatra::MultiRoute

  VALID_PARAMS = [
    CustomFace::DEFAULT_FEATURE_STACKING_ORDER,
    :background_color,
    :emoji_id,
    :file_format,
    :filename,
    :order,
    :output,
    :padding,
    :renderer,
    :size,
    :time,
    :twemoji_version
  ].flatten.freeze

  get '/v1/faces', '/v1/faces/' do
    json(Face.all(params[:twemoji_version]).keys)
  end

  get '/v1/faces/layers', '/v1/faces/layers/' do
    json(Face.all(params[:twemoji_version]))
  end

  get '/v1/faces/features', '/v1/faces/features/' do
    faces = Face.all(params[:twemoji_version])
    faces.each do |key, value|
      faces[key] = Face.features_from_layers(value)
    end

    json(faces)
  end

  get '/v1/faces/random', '/v1/faces/random/' do
    validate
    face = RandomCustomFace.new(params)
    process_valid_request(face, face_url(face))
  rescue StandardError => e
    runtime_error(e)
  end

  get '/v1/faces/:emoji_id', '/v1/faces/:emoji_id/' do
    validate
    process_valid_request(CustomFace.new(params))
  rescue StandardError => e
    runtime_error(e)
  end

  not_found do
    content_type 'application/json'
    message =
      "Endpoint not found: #{request.request_method} #{request.path_info}"\
      ' | Valid endpoints: GET /faces, GET /faces/{emoji_id}'
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

    params = validate_params(@params.symbolize_keys)
    raise 'No valid parameters detected' if params.empty?
  end

  def process_valid_request(face, url = nil)
    resource = get_resource(face)

    case @output
    when 'json'
      url.nil? ? json(resource) : json(resource, url)
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

  def face_url(face)
    url = "https://#{@env['HTTP_HOST']}/v1/faces/#{face.url}"

    request.params.each do |key, value|
      next if CustomFace::DEFAULT_FEATURE_STACKING_ORDER.include?(key.to_sym)

      feature_hash = { key => value }
      url =
        "#{url}#{'&' unless url.end_with?('?')}#{URI.encode_www_form(feature_hash)}"
    end

    url
  end

  def json(data, links_self = request.url)
    content_type 'application/json'
    {
      success: true,
      data: data,
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
