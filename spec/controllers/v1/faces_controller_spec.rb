# frozen_string_literal: true

require_relative '../../spec_helper'
require 'rack/test'
require_relative '../../../app/controllers/v1/faces_controller'

RSpec.describe FacesController do
  include Rack::Test::Methods

  def app
    described_class
  end

  before do
    header 'Host', 'localhost'
  end

  it 'returns a list of faces' do
    get '/v1/faces'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    expect(body['data']).to be_a(Hash)
  end

  it 'returns a random face' do
    get '/v1/faces/random'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    expect(body['links']).to be_a(Hash)
    expect(body['links']['self']).to include('/v1/faces')
  end

  it 'returns details for a specific face' do
    faces = Face.all(Twemoji.latest)
    emoji_id = faces.keys.first

    get "/v1/faces/#{emoji_id}"

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    expect(body['data'].keys).to include(emoji_id.to_s)
  end

  it 'returns 400 when emoji_id is missing' do
    get '/v1/faces/'

    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be false
    expect(body['error']).to include("Parameter 'emoji_id' is required")
  end

  it 'filters faces by include_features' do
    get '/v1/faces', include_features: 'head'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    body['data'].each_value do |face|
      expect(face['layers'].values).to all(eq('head'))
    end
  end

  it 'filters faces by include_layers and preserves empty entries when requested' do
    get '/v1/faces', include_layers: '999', include_empty_layers: 'true'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    expect(body['data']).not_to be_empty
    body['data'].each_value do |face|
      expect(face['layers']).to eq({})
    end
  end

  it 'removes glyph when include_glyph is false' do
    get '/v1/faces', include_glyph: 'false'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    body['data'].each_value do |face|
      expect(face).not_to have_key('glyph')
    end
  end

  it 'returns features-indexed response when index_by=features' do
    get '/v1/faces', index_by: 'features'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    body['data'].each_value do |face|
      expect(face['layers']).to be_a(Hash)
      expect(face['layers'].keys.first).to match(/^[a-z_]+$/)
    end
  end

  it 'returns 400 for invalid index_by param' do
    get '/v1/faces', index_by: 'invalid'

    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be false
  end
end
