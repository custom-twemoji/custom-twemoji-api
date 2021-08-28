# frozen_string_literal: true

require 'jwt'

class JwtAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      require 'pry'
      binding.pry
      puts 'end of pry'
      response = JWT.decode(bearer, ENV['JWT_SECRET'], true, options)
      payload = response[0]
      header = response[1]

      env[:scopes] = payload['scopes']
      env[:user] = payload['user']

      @app.call(env)
    rescue JWT::DecodeError
      [
        401,
        { 'Content-Type': 'text/plain' },
        ['A token must be passed.']
      ]
    rescue JWT::ExpiredSignature
      content_type :json
      message = 'The token has expired'
      error 403, { error: message }.to_json
    rescue JWT::InvalidIssuerError
      [
        403,
        { 'Content-Type': 'text/plain' },
        ['The token does not have a valid issuer.']
      ]
    rescue JWT::InvalidIatError
      [
        403,
        { 'Content-Type': 'text/plain' },
        ['The token does not have a valid "issued at" time.']
      ]
    end
  end
end
