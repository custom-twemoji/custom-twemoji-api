# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack/test'
require_relative '../../app/middleware/cloudflare_origin_auth'

RSpec.describe CloudflareOriginAuth do
  include Rack::Test::Methods

  let(:upstream) do
    ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['ok']] }
  end

  let(:env) { Rack::MockRequest.env_for('/v1/faces/1f47b', method: :get) }

  context 'when CLOUDFLARE_ORIGIN_SECRET is set' do
    before { stub_secret('abc123') }

    it 'rejects requests without the header' do
      response = described_class.new(upstream).call(env)

      expect(response[0]).to eq(403)
      expect(response[1]['Content-Type']).to eq('application/json')
      body = JSON.parse(response[2][0])
      expect(body['success']).to be false
      expect(body['message']).to eq('Forbidden')
    end

    it 'rejects requests with a wrong value' do
      env['HTTP_X_ORIGIN_SECRET'] = 'wrong'

      expect(described_class.new(upstream).call(env)[0]).to eq(403)
    end

    it 'passes requests with the correct value' do
      env['HTTP_X_ORIGIN_SECRET'] = 'abc123'

      expect(described_class.new(upstream).call(env)[0]).to eq(200)
    end
  end

  context 'when CLOUDFLARE_ORIGIN_SECRET is not set' do
    before { stub_secret(nil) }

    it 'passes requests through' do
      expect(described_class.new(upstream).call(env)[0]).to eq(200)
    end
  end

  def stub_secret(value)
    allow(ENV).to receive(:[]).and_wrap_original do |original, key|
      key == 'CLOUDFLARE_ORIGIN_SECRET' ? value : original.call(key)
    end
    allow(ENV).to receive(:fetch).and_wrap_original do |original, key, *args|
      key == 'CLOUDFLARE_ORIGIN_SECRET' ? value : original.call(key, *args)
    end
  end
end

RSpec.describe CloudflareOriginAuth, 'mounted in a Sinatra app' do
  include Rack::Test::Methods

  let(:dummy_class) do
    Class.new(Sinatra::Base) do
      use CloudflareOriginAuth

      get '/v1/status' do
        'ok'
      end
    end
  end

  def app
    dummy_class
  end

  before do
    allow(ENV).to receive(:[]).and_wrap_original do |original, key|
      key == 'CLOUDFLARE_ORIGIN_SECRET' ? 'abc123' : original.call(key)
    end
    allow(ENV).to receive(:fetch).and_wrap_original do |original, key, *args|
      key == 'CLOUDFLARE_ORIGIN_SECRET' ? 'abc123' : original.call(key, *args)
    end
    header 'Host', 'localhost'
  end

  it 'blocks requests without the header' do
    get '/v1/status'

    expect(last_response.status).to eq(403)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be false
  end

  it 'passes requests with the correct header' do
    header 'x-origin-secret', 'abc123'
    get '/v1/status'

    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('ok')
  end
end
