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
  :base_emoji_id,
  :order,
  :output,
  :filename,
  :time,
  :twemoji_version
].flatten.freeze

get '/' do
  redirect 'https://github.com/blakegearin/custom-twemoji-api'
end

get '/faces' do
  json(Face.all(params[:twemoji_version].presence))
end

get '/faces/:base_emoji_id/:file_format', '/faces/:file_format' do
  @output = params[:output]
  case @params[:file_format]
  when 'svg', 'png'
    params = validate_params(symbolize_params)
    return if params.empty?

    resource = get_resource_by_file_format(@params[:file_format], CustomFace.new(params))
  else
    message = "File format not supported: #{@params[:type]} | Valid file formats: svg, png"
    error 405, { error: message }.to_json
  end

  params[:output] == 'json' ? json(resource) : resource
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
    ' | Valid endpoints: GET /faces'
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

def get_resource_by_file_format(file_format, resource)
  case file_format
  when 'svg'
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
