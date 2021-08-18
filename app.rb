# frozen_string_literal: true

require 'sinatra'

require_relative 'emoji'

get '/xml' do
  params = validate_and_symbolize
  return if params.empty?

  Emoji.new(params).xml
end

get '/svg' do
  params = validate_and_symbolize
  return if params.empty?

  content_type 'application/octet-stream'
  xml = Emoji.new(params).xml
  xml.bytes.to_a.pack('C*').force_encoding('utf-8')
end

get '/png' do
  params = validate_and_symbolize
  return if params.empty?

  content_type 'image/png'

  Emoji.new(params).png
end

private

def validate_and_symbolize
  params[:time] = Time.now.getutc.to_i

  valid_params = [DEFAULT_STACKING_ORDER, :order, :time].flatten
  Hash[
    params.map do |(k,v)|
      [ k.to_sym, v ]
    end
  ].select { |key, value| valid_params.include?(key) }
end
