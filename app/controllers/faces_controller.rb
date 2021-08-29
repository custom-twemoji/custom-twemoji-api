# frozen_string_literal: true

require 'base64'
require 'sinatra/base'
require 'sinatra/multi_route'

require_relative '../helpers/hash'
require_relative '../models/custom_face'
require_relative '../models/random_custom_face'

# Defines the Faces endpoints
class FacesController < Sinatra::Base
  register Sinatra::MultiRoute

  VALID_PARAMS = [
    CustomFace::DEFAULT_FEATURE_STACKING_ORDER,
    :emoji_id,
    :file_format,
    :filename,
    :order,
    :output,
    :raw,
    :size,
    :time,
    :twemoji_version
  ].flatten.freeze

  get '/faces', '/faces/' do
    json(Face.all(params[:twemoji_version].presence))
  end

  get '/faces/random' do
    validate
    process_valid_request(RandomCustomFace.new(params))
  rescue StandardError => e
    runtime_error(e)
  end

  get '/faces/:emoji_id' do
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

  def validate
    @output = params[:output]
    @file_format = @params[:file_format]
    case @file_format
    when nil, 'svg', 'png'
      params = validate_params(@params.symbolize_keys)
      raise 'No valid parameters detected' if params.empty?
    else
      message = "File format not supported: #{@params[:type]} | Valid file formats: svg, png"
      error 405, { error: message }.to_json
    end
  end

  def process_valid_request(face)
    resource = get_resource(face)
    case @output
    when 'json'
      json(resource)
    else
      resource
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

    filename = params[:filename].presence || resource.to_s
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
    return Base64.encode64(resource.png).gsub(/\n/, '') if @output == 'json'

    content_type 'image/png'
    set_content_disposition(resource, __method__.to_s)

    resource.png
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
