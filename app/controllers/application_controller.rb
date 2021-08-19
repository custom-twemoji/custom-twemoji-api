# frozen_string_literal: true

require 'logger'
require 'sinatra'
require 'sinatra/custom_logger'

require_relative '../models/emoji'

set :logger, Logger.new(STDOUT)

get '/faces/:file_format' do
  file_format = @params[:file_format]

  case file_format
  when 'svg'
    params = validate_and_symbolize
    return if params.empty?

    emoji = Emoji.new(params)

    content_type 'image/svg+xml'
    set_content_disposition(emoji, file_format)

    # emoji.xml.bytes.to_a.pack('C*').force_encoding('utf-8')
    emoji.xml
  when 'png'
    params = validate_and_symbolize
    return if params.empty?

    emoji = Emoji.new(params)

    content_type 'image/png'
    set_content_disposition(emoji, file_format)

    emoji.png
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

def set_content_disposition(emoji, file_extension)
  if params[:download] == 'true'
    filename = params[:filename].presence || emoji.to_s
    full_filename = "#{filename}.#{file_extension}"

    # Good explanation on this: https://stackoverflow.com/a/20509354/5988852
    headers['Content-Disposition'] = "attachment;filename=\"#{full_filename}\""
  end
end

def validate_and_symbolize
  params[:time] = Time.now.getutc.to_i

  valid_params =
    [
      DEFAULT_FEATURE_STACKING_ORDER,
      :order,
      :download,
      :filename,
      :time,
      :twemoji_version
    ].flatten
  Hash[
    params.map do |(k,v)|
      [ k.to_sym, v ]
    end
  ].select { |key, value| valid_params.include?(key) }
end