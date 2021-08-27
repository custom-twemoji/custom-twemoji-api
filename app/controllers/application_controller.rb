# frozen_string_literal: true

require 'logger'
require 'sinatra/base'
require 'sinatra/custom_logger'

# Defines the top-level application
class ApplicationController < Sinatra::Base
  set :logger, Logger.new($stdout)

  configure :development, :production do
    logger = Logger.new($stdout)
    logger.level = Logger::DEBUG if development?
    set :logger, logger
  end

  get '/' do
    redirect 'https://github.com/blakegearin/custom-twemoji-api'
  end

  run! if app_file == $PROGRAM_NAME
end
