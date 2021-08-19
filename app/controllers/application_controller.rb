# frozen_string_literal: true

require 'logger'
require 'sinatra'
require 'sinatra/custom_logger'

require_relative '../models/emoji'

set :logger, Logger.new(STDOUT)

get '/faces/:type' do
  case @params[:type]
  when 'xml'
    params = validate_and_symbolize
    return if params.empty?

    Emoji.new(params).xml
  when 'svg'
    params = validate_and_symbolize
    return if params.empty?

    content_type 'application/octet-stream'
    xml = Emoji.new(params).xml
    xml.bytes.to_a.pack('C*').force_encoding('utf-8')
  when 'png'
    params = validate_and_symbolize
    return if params.empty?

    content_type 'image/png'

    Emoji.new(params).png
  else
    message = "File format not supported: #{@params[:type]} | Valid file formats: xml, svg, png"
    error 405, { error: message }.to_json
  end
rescue => e
  logger.error(e.message)
  error 500, { error: e.message }.to_json
end

not_found do
  message =
      "Endpoint not found: #{request.request_method} #{request.path_info}"\
      '| Valid endpoints: GET /faces'
  error 404, { error: message }.to_json
end

private

def validate_and_symbolize
  params[:time] = Time.now.getutc.to_i

  valid_params =
    [
      DEFAULT_FEATURE_STACKING_ORDER,
      :order,
      :time,
      :twemoji_version
    ].flatten
  Hash[
    params.map do |(k,v)|
      [ k.to_sym, v ]
    end
  ].select { |key, value| valid_params.include?(key) }
end
