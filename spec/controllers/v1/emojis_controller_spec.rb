# frozen_string_literal: true

require_relative '../../spec_helper'
require 'rack/test'
require_relative '../../../app/controllers/v1/emojis_controller'

RSpec.describe EmojisController do
  include Rack::Test::Methods

  def app
    described_class
  end

  before do
    stub_request(:get, /raw.githubusercontent.com/).to_return(status: 200, body: '<svg><g id="emoji"></g></svg>')
    header 'Host', 'localhost'
  end

  it 'returns 405 for unsupported output param' do
    post '/v1/emojis?output=unsupported', '[]', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(405)
  end

  it 'returns 405 for unsupported file_format param' do
    post '/v1/emojis?file_format=bad', '[]', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(405)
  end

  it 'returns json resource when body present' do
    fake = double('CustomLayersEmoji', xml: '<svg></svg>', svg: '<svg></svg>', png: 'PNGDATA', unique_string: 'u1')
    allow(CustomLayersEmoji).to receive(:new).and_return(fake)

    post '/v1/emojis', '[{"emoji":"1f600","layers":0}]', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    expect(body['resource']).to eq(fake.xml)
  end

  it 'returns image/png when requested with file_format=png and output=image' do
    fake = double('CustomLayersEmoji', xml: '<svg></svg>', svg: '<svg></svg>', png: 'PNGDATA', unique_string: 'u1')
    allow(CustomLayersEmoji).to receive(:new).and_return(fake)

    post '/v1/emojis?file_format=png&output=image&renderer=imagemagick', '[{"emoji":"1f600","layers":0}]', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Type']).to match(/image\/png/)
  end

  it 'returns an svg image when output=image and file_format=svg' do
    fake = double('CustomLayersEmoji', xml: '<svg></svg>', svg: '<svg></svg>', png: 'PNGDATA', unique_string: 'u1')
    allow(CustomLayersEmoji).to receive(:new).and_return(fake)

    post '/v1/emojis?file_format=svg&output=image', '[{"emoji":"1f600","layers":0}]', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Type']).to match(/image\/svg\+xml/)
    expect(last_response.body).to eq('<svg></svg>')
  end

  it 'returns a downloadable svg when output=download and file_format=svg' do
    fake = double('CustomLayersEmoji', xml: '<svg></svg>', svg: '<svg></svg>', png: 'PNGDATA', unique_string: 'u1')
    allow(CustomLayersEmoji).to receive(:new).and_return(fake)

    post '/v1/emojis?file_format=svg&output=download&filename=custom-name', '[{"emoji":"1f600","layers":0}]', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Type']).to match(/image\/svg\+xml/)
    expect(last_response.headers['Content-Disposition']).to include('attachment;filename="custom-name.svg"')
    expect(last_response.body).to eq('<svg></svg>')
  end

  it 'returns Base64 encoded png in JSON using canvg renderer' do
    fake = double('CustomLayersEmoji', xml: '<svg></svg>', svg: '<svg></svg>', png: 'PNGDATA', unique_string: 'u1')
    allow(CustomLayersEmoji).to receive(:new).and_return(fake)

    post '/v1/emojis?file_format=png&renderer=canvg', '[{"emoji":"1f600","layers":0}]', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Type']).to match(/application\/json/)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    expect(body['resource']).to eq(Base64.encode64('PNGDATA').gsub("\n", ''))
  end

  it 'returns image content/html when output=image and file_format=png uses default canvg renderer' do
    fake = double('CustomLayersEmoji', xml: '<svg></svg>', svg: '<svg></svg>', png: 'PNGDATA', unique_string: 'u1')
    allow(CustomLayersEmoji).to receive(:new).and_return(fake)

    post '/v1/emojis?file_format=png&output=image', '[{"emoji":"1f600","layers":0}]', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Type']).to match(/text\/html/)
  end

  it 'returns 500 when POST /v1/emojis has no body' do
    post '/v1/emojis', '', { 'CONTENT_TYPE' => 'application/json' }

    expect(last_response.status).to eq(500)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be false
  end

  it 'returns 404 for unknown emoji endpoint' do
    get '/v1/emojis/unknown/path'

    expect(last_response.status).to eq(404)
    body = JSON.parse(last_response.body)
    expect(body['error']).to match(/Endpoint not found/)
  end
end
