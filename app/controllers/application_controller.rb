# frozen_string_literal: true

require 'base64'
require 'logger'
require 'sinatra'
require 'sinatra/custom_logger'
require 'sinatra/multi_route'

require_relative '../models/custom_face'

set :logger, Logger.new($stdout)

VALID_PARAMS = [
  CustomFace::DEFAULT_FEATURE_STACKING_ORDER,
  :emoji_id,
  :file_format,
  :filename,
  :order,
  :output,
  :time,
  :twemoji_version
].flatten.freeze

get '/' do
  redirect 'https://github.com/blakegearin/custom-twemoji-api'
end

get '/faces', '/faces/' do
  json(Face.all(params[:twemoji_version].presence))
end

get '/faces/:emoji_id' do
  @output = params[:output]
  @file_format = @params[:file_format]
  case @file_format
  when nil, 'svg', 'png'
    params = validate_params(symbolize_params)
    return if params.empty?

    resource = get_resource(CustomFace.new(params))
    @output == 'json' ? json(resource) : resource
  else
    message = "File format not supported: #{@params[:type]} | Valid file formats: svg, png"
    error 405, { error: message }.to_json
  end
rescue StandardError => e
  logger.error(e.message)
  response = {
    success: false,
    error: e.message
  }
  error 500, response.to_json
end

not_found do
  message =
    "Endpoint not found: #{request.request_method} #{request.path_info}"\
    ' | Valid endpoints: GET /faces, GET /faces/{emoji_id}'
  error 404, { error: message }.to_json
end

private

def symbolize_params
  Hash[
    params.map do |(k, v)|
      [k.to_sym, v]
    end
  ]
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

  resource.xml
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
