# frozen_string_literal: true

require 'dotenv/load'
require 'json'
require 'jwt'
require 'logger'
require 'sinatra/base'
require 'sinatra/custom_logger'
require 'sinatra/multi_route'

LOGGER = Logger.new($stdout).tap do |logger|
  logger.formatter = proc do |severity, datetime, _progname, msg|
    "[#{datetime} #{severity}] #{msg}\n"
  end
end

require_relative '../helpers/jwt'

# Defines the top-level application
class ApplicationController < Sinatra::Base
  register Sinatra::MultiRoute

  configure :development, :production do
    LOGGER.level = Logger::DEBUG if development?
    set :logger, LOGGER
  end

  get '/', '/v1', '/v1/' do
    redirect 'https://github.com/blakegearin/custom-twemoji-api'
  end

  def initialize
    super

    @logins = {
      tomdelonge: 'allthesmallthings',
      markhoppus: 'therockshow',
      travisbarker: 'whatsmyageagain'
    }
  end

  post '/login' do
    username = params[:username]
    password = params[:password]

    content_type :json
    if @logins[username.to_sym] == password
      { token: token(username) }.to_json
    else
      message = 'Unauthorized'
      error 401, { error: message }.to_json
    end
  end

  # post '/login' do
  #   username = params[:username]
  #   password = params[:password]

  #   if @logins[username.to_sym] == password
  #     content_type :json
  #     { message: "You logged in. Yay you!" }.to_json
  #   else
  #     halt 401
  #   end
  # end

  get '/money' do
    process_request(request, 'view_money') do |req, username|
      { hello: 'world' }.to_json
    end
  end

  run! if app_file == $PROGRAM_NAME

  private

  def token(username)
    JWT.encode(payload(username), ENV['JWT_SECRET'], 'HS256')
  end

  def payload(username)
    {
      exp: Time.now.to_i + 60 * 60,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      scopes: ['add_money', 'remove_money', 'view_money'],
      user: {
        username: username
      }
    }
  end

  def process_request(req, scope)
    scopes, user = req.env.values_at :scopes, :user
    # require 'pry'
    # binding.pry
    # puts 'end of pry'
    scopes.include?(scope) ? yield(req, user['username'].to_sym) : halt(403)
  end
end
