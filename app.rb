# frozen_string_literal: true

require 'logger'
require 'sinatra'
require 'sinatra/custom_logger'

require_relative 'emoji'

set :logger, Logger.new(STDOUT)

get '/xml' do
  params = validate_and_symbolize
  return if params.empty?

  Emoji.new(params).xml
rescue => e
  logger.error(e.message)
  error 404, { error: e.message }.to_json
end

get '/svg' do
  params = validate_and_symbolize
  return if params.empty?

  content_type 'application/octet-stream'
  xml = Emoji.new(params).xml
  xml.bytes.to_a.pack('C*').force_encoding('utf-8')
rescue => e
  logger.error(e.message)
  error 404, { error: e.message }.to_json
end

get '/png' do
  params = validate_and_symbolize
  return if params.empty?

  content_type 'image/png'

  Emoji.new(params).png
rescue => e
  logger.error(e.message)
  error 404, { error: e.message }.to_json
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
