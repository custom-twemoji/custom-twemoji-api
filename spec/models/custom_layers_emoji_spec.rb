# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CustomLayersEmoji do
  let(:params) do
    {
      twemoji_version: '14.1.0',
      emoji_id: '1f600',
      body: [],
      absolute_paths: 'false',
      remove_groups: 'false'
    }
  end

  let(:twemoji_xml) do
    Nokogiri::XML('<svg><path d="M0 0"/><path d="M1 1"/><path d="M2 2"/></svg>').at('svg')
  end

  before do
    allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: twemoji_xml))
    allow(Twemoji).to receive(:new).and_return(double(xml: twemoji_xml))
    allow(Face).to receive(:find_with_layers).and_return('layers' => { 0 => 'head' })
  end

  describe '#to_s' do
    it 'returns the base identifier when no body layers are provided' do
      emoji = described_class.new(params)
      expect(emoji.to_s).to eq('base-1f600')
    end

    it 'includes layer identifiers when body layers are provided' do
      emoji = described_class.new(params.merge(body: [{ emoji: 'U+1F600', layers: 0 }]))
      expect(emoji.to_s).to include('base-1f600')
    end
  end

  describe '#get_layer_by_number' do
    it 'raises when the requested layer is missing' do
      emoji = described_class.new(params)
      xml = Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')
      expect do
        emoji.send(:get_layer_by_number, xml, 5)
      end.to raise_error(/Layer number '5' is not present on emoji/)
    end
  end

  describe '#pluck_layers_from_twemoji' do
    it 'accepts a string range of layers' do
      emoji = described_class.new(params)
      layers = emoji.send(:pluck_layers_from_twemoji, twemoji_xml, '0..1', '1f600', nil)

      expect(layers.map(&:name)).to eq(%w[path path])
      expect(layers[0].attributes['id'].value).to eq('1f600-0')
    end

    it 'accepts reverse string ranges and preserves order' do
      emoji = described_class.new(params)
      layers = emoji.send(:pluck_layers_from_twemoji, twemoji_xml, '2..0', '1f600', nil)

      expect(layers.map(&:attributes).map { |attr| attr['id'].value }).to eq(%w[1f600-2 1f600-1 1f600-0])
    end

    it 'accepts layer hashes with fill values' do
      emoji = described_class.new(params)
      layers = emoji.send(:pluck_layers_from_twemoji, twemoji_xml, [{ layer: 2, fill: 'red' }], '1f600', nil)

      expect(layers.length).to eq(1)
      expect(layers[0].attributes['fill'].value).to eq('red')
    end

    it 'raises when string layer range format is unsupported' do
      emoji = described_class.new(params)
      expect do
        emoji.send(:pluck_layers_from_twemoji, twemoji_xml, 'bad', '1f600', nil)
      end.to raise_error(CustomTwemojiApiError, /Didn't match supported pattern/)
    end
  end

  describe '#get_xml_and_emoji_id' do
    it 'retrieves and caches a twemoji by emoji id' do
      emoji = described_class.new(params)
      body_object = { emoji: 'U+1F600', layers: '0..1', absolute_paths: 'false', remove_groups: 'false' }

      allow(Twemoji).to receive(:new).and_return(double(xml: twemoji_xml))
      xml, twemojis, identifier = emoji.send(:get_xml_and_emoji_id, body_object, {})

      expect(xml.length).to eq(2)
      expect(twemojis.keys).to include('1f600')
      expect(identifier).to include('1f600')
    end

    it 'uses AbsoluteTwemoji when absolute_paths is true' do
      emoji = described_class.new(params)
      body_object = { emoji: 'U+1F600', layers: '0..1', absolute_paths: 'true', remove_groups: 'false' }

      allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: twemoji_xml))
      result = emoji.send(:get_xml_and_emoji_id, body_object, {})

      expect(result[0].length).to eq(2)
    end

    it 'raises a descriptive error when layer extraction fails' do
      emoji = described_class.new(params)
      body_object = { emoji: 'U+1F600', layers: 'bad', absolute_paths: 'false', remove_groups: 'false' }

      allow(Twemoji).to receive(:new).and_return(double(xml: twemoji_xml))
      expect do
        emoji.send(:get_xml_and_emoji_id, body_object, {})
      end.to raise_error(/Layers as a string only supports x..y where x and y are integers/)
    end
  end
end
