# frozen_string_literal: true

require_relative '../../spec_helper'
require 'rack/test'
require_relative '../../../app/controllers/v1/custom_faces_controller'

RSpec.describe CustomFacesController do
  include Rack::Test::Methods

  def app
    described_class
  end

  before do
    # Stub calls to GitHub raw content used by Twemoji/AbsoluteTwemoji
    svg_body = '<svg><g id="emoji">'
    9.times { svg_body += '<path d="M0 0 H10 V10 H0 Z" />' }
    svg_body += '</g></svg>'
    stub_request(:get, /raw.githubusercontent.com/).to_return(status: 200, body: svg_body)
    header 'Host', 'localhost'
    # Prevent heavy Twemoji parsing by stubbing RandomCustomFace to return a
    # minimal object with the attributes the controller expects.
    fake_face = double('RandomCustomFace', xml: '<svg></svg>', description: 'fake', url: 'fake')
    allow(RandomCustomFace).to receive(:new).and_return(fake_face)
  end

  it 'returns a random custom face as json' do
    get '/v1/custom_faces/random'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    expect(body['data']).to be_a(Hash)
    expect(body['data']['output']).not_to be_nil
  end

  it 'returns a mashup as json' do
    mash = double('MashupCustomFace', xml: '<svg></svg>', description: 'mash', url: 'mash')
    expect(MashupCustomFace).to receive(:new).and_return(mash)

    get '/v1/custom_faces/mashup', emojis: '1,2', amount: '2'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
  end

  it 'returns a specific emoji as json' do
    cf = double('CustomFace', xml: '<svg></svg>', description: 'one', url: 'one')
    expect(CustomFace).to receive(:new).and_return(cf)

    get '/v1/custom_faces/1', emoji_id: '1'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
  end

  it 'returns png content for image output and sets Content-Type' do
    face = double('RandomCustomFace', xml: '<svg></svg>', description: 'd', url: 'u')
    allow(RandomCustomFace).to receive(:new).and_return(face)
    allow(face).to receive(:png).and_return('<html>canvg</html>')

    get '/v1/custom_faces/random', file_format: 'png', output: 'image'

    expect(last_response.status).to eq(200)
    # renderer for image fallback should be canvg => text/html
    expect(last_response.headers['Content-Type']).to include('text/html')
    expect(last_response.body).to include('canvg')
  end

  it 'returns image/png when renderer=imagemagick and file_format=png' do
    face = double('RandomCustomFace', xml: '<svg></svg>', description: 'd', url: 'u')
    allow(RandomCustomFace).to receive(:new).and_return(face)
    allow(face).to receive(:png).and_return('PNGDATA')

    get '/v1/custom_faces/random', file_format: 'png', output: 'image', renderer: 'imagemagick'

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Type']).to include('image/png')
    expect(last_response.body).to eq('PNGDATA')
  end

  it 'returns Base64 encoded png resource in json when renderer=canvg' do
    face = double('RandomCustomFace', xml: '<svg></svg>', description: 'd', url: 'u')
    allow(RandomCustomFace).to receive(:new).and_return(face)
    allow(face).to receive(:png).and_return('PNGDATA')

    get '/v1/custom_faces/random', file_format: 'png', renderer: 'canvg'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
    expect(body['data']['output']).to eq(Base64.encode64('PNGDATA').gsub("\n", ''))
  end

  it 'returns svg download when file_format=svg and output=download' do
    mash = double('MashupCustomFace', xml: '<svg></svg>', svg: '<svg></svg>', description: 'mash', url: 'mash',
                                      unique_string: 'mash')
    expect(MashupCustomFace).to receive(:new).and_return(mash)

    get '/v1/custom_faces/mashup', file_format: 'svg', output: 'download', emojis: '1,2', amount: '2',
                                   filename: 'myfile'

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Disposition']).to include('myfile.svg')
    expect(last_response.headers['Content-Type']).to include('image/svg+xml')
    expect(last_response.body).to eq('<svg></svg>')
  end

  it 'returns 405 for unsupported output param' do
    get '/v1/custom_faces/random', output: 'bad'

    expect(last_response.status).to eq(405)
    body = JSON.parse(last_response.body)
    expect(body['error']).to match(/Output not supported/)
  end

  it 'returns 405 for unsupported file_format param' do
    get '/v1/custom_faces/random', file_format: 'bad'

    expect(last_response.status).to eq(405)
    body = JSON.parse(last_response.body)
    expect(body['error']).to match(/File format not supported/)
  end

  it 'returns 500 when CustomFace initialization raises' do
    expect(CustomFace).to receive(:new).and_raise(StandardError.new('bad'))

    get '/v1/custom_faces/1', emoji_id: '1'

    expect(last_response.status).to eq(500)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be false
    expect(body['error']).to include('bad')
  end

  it 'returns a mashup as json' do
    mash = double('MashupCustomFace', xml: '<svg></svg>', description: 'mash', url: 'mash')
    expect(MashupCustomFace).to receive(:new).and_return(mash)

    get '/v1/custom_faces/mashup', emojis: '1,2', amount: '2'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
  end

  it 'returns a specific emoji as json' do
    cf = double('CustomFace', xml: '<svg></svg>', description: 'one', url: 'one')
    expect(CustomFace).to receive(:new).and_return(cf)

    get '/v1/custom_faces/1', emoji_id: '1'

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be true
  end

  it 'sets Content-Disposition for download output' do
    face = double('RandomCustomFace', xml: '<svg></svg>', description: 'd', url: 'u', unique_string: 'uniq')
    allow(RandomCustomFace).to receive(:new).and_return(face)
    allow(face).to receive(:png).and_return('PNGDATA')

    get '/v1/custom_faces/random', file_format: 'png', output: 'download', filename: 'myfile'

    expect(last_response.status).to eq(200)
    expect(last_response.headers['Content-Disposition']).to include('myfile.png')
  end

  it 'appends extra params to face url' do
    face = double('RandomCustomFace', xml: '<svg></svg>', description: 'd', url: 'emoji')
    allow(RandomCustomFace).to receive(:new).and_return(face)

    get '/v1/custom_faces/random', foo: 'bar'

    body = JSON.parse(last_response.body)
    expect(body['links']['self']).to include('foo=bar')
  end

  it 'returns JSON error when underlying code raises a CustomTwemojiApiError' do
    expect(RandomCustomFace).to receive(:new).and_raise(CustomTwemojiApiError.new(400))

    get '/v1/custom_faces/random'

    expect(last_response.status).to eq(400)
    body = JSON.parse(last_response.body)
    expect(body['success']).to be false
    expect(body['error']).not_to be_nil
  end
end
