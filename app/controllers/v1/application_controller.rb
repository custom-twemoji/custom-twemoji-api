# frozen_string_literal: true

require 'logger'
require 'sinatra/base'
require 'sinatra/custom_logger'
require 'sinatra/multi_route'

LOGGER = Logger.new($stdout).tap do |logger|
  logger.formatter = proc do |severity, datetime, _progname, msg|
    "[#{datetime} #{severity}] #{msg}\n"
  end
end

# Defines the top-level application
class ApplicationController < Sinatra::Base
  register Sinatra::MultiRoute

  configure :development, :production do
    LOGGER.level = Logger::DEBUG if development?
    set :logger, LOGGER
  end

  get '/', '/v1', '/v1/'  do
    redirect 'https://github.com/blakegearin/custom-twemoji-api'
  end

  run! if app_file == $PROGRAM_NAME
end
