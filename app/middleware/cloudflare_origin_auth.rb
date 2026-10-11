# frozen_string_literal: true

require 'sinatra/base'

# Rack middleware that rejects requests missing the internal Cloudflare
# origin-secret header injected by a Cloudflare Transform Rule, unless no
# secret has been deployed.
class CloudflareOriginAuth
  HEADER = 'HTTP_X_ORIGIN_SECRET'

  def initialize(app)
    @app = app
  end

  def call(env)
    secret = ENV.fetch('CLOUDFLARE_ORIGIN_SECRET', nil)
    return @app.call(env) if secret.nil? || secret.empty?

    if Rack::Utils.secure_compare(env[HEADER].to_s, secret)
      @app.call(env)
    else
      headers = { 'Content-Type' => 'application/json' }
      [403, headers, [{ success: false, message: 'Forbidden' }.to_json]]
    end
  end
end
