# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CustomFace do
  let(:params) do
    {
      twemoji_version: '14.1.0',
      background_color: 'transparent'
    }
  end

  before do
    allow(Face).to receive(:find_with_glyph).and_return('🤡')
    allow(Face).to receive(:find_with_features).and_return(head: [0], mouth: [13])
    allow(Face).to receive(:find_with_layers).and_return('layers' => { 0 => 'head' })
    allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))
  end

  describe '#description' do
    it 'returns an array even when no features are present' do
      emoji = described_class.new(params)
      expect(emoji.description).to eq([])
    end
  end

  describe '#unique_string' do
    it 'returns an empty string when no feature params are present' do
      emoji = described_class.new(params)
      expect(emoji.unique_string).to eq('')
    end
  end

  describe '#define_url' do
    it 'returns a query string placeholder with no feature params' do
      emoji = described_class.new(params)
      expect(emoji.send(:define_url)).to start_with('?')
      expect(emoji.send(:define_url)).to include('cheeks=')
      expect(emoji.send(:define_url)).to include('mouth=')
    end

    it 'builds a URL fragment with provided feature params' do
      emoji = described_class.new(params.merge(head: '1f600', mouth: '1f600'))
      query_string = emoji.send(:define_url)

      expect(query_string).to start_with('1f600?')
      expect(query_string).not_to include('head=1f600')
      expect(query_string).to include('mouth=1f600')
    end
  end

  describe '#unique_string' do
    it 'omits falsy and blank feature params from the output' do
      allow(Face).to receive(:find_with_glyph).and_return('🤡')
      allow(Face).to receive(:find_with_features).and_return(head: [0], mouth: [13])
      allow(Face).to receive(:find_with_layers).and_return('layers' => { 0 => 'head' })
      allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))

      emoji = described_class.new(params.merge(emoji_id: '1f921', head: '1f600', cheeks: 'false', mouth: '',
                                               eyewear: '1f576'))

      expect(emoji.unique_string).to include('base-1f921')
      expect(emoji.unique_string).to include('head-1f600')
      expect(emoji.unique_string).to include('eyewear-1f576')
      expect(emoji.unique_string).not_to include('cheeks')
      expect(emoji.unique_string).not_to include('mouth-')
    end
  end

  describe '#description' do
    it 'returns the base and feature glyph mapping when features are present' do
      allow(Face).to receive(:find_with_glyph) do |_, emoji_id|
        case emoji_id
        when '1f921' then '🤡'
        when '1f600' then '😀'
        else
          '❓'
        end
      end
      allow(Face).to receive(:find_with_features).and_return(head: [0], mouth: [13])
      allow(Face).to receive(:find_with_layers).and_return('layers' => { 0 => 'head' })
      allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))

      emoji = described_class.new(params.merge(emoji_id: '1f921', head: '1f600', mouth: '1f600'))
      result = emoji.description

      expect(result.first).to eq(
        feature: 'base',
        codepoint: '1f921',
        glyph: '🤡'
      )
      expect(result).to include(
        feature: :head,
        codepoint: '1f600',
        glyph: '😀'
      )
      expect(result).to include(
        feature: :mouth,
        codepoint: '1f600',
        glyph: '😀'
      )
    end
  end

  describe '#validate_feature_param' do
    it 'converts a false string into an empty feature value' do
      allow(Face).to receive(:find_with_glyph).and_return('🤡')
      allow(Face).to receive(:find_with_features).and_return(head: [0], mouth: [13])
      allow(Face).to receive(:find_with_layers).and_return('layers' => { 0 => 'head' })
      allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))

      emoji = described_class.new(params.merge(emoji_id: '1f921', head: 'false'))
      emoji.send(:validate_feature_param, :head)

      expect(emoji.instance_variable_get(:@params)[:head]).to eq('')
    end

    it 'raises when the feature code point is invalid' do
      allow(Face).to receive(:find_with_glyph).and_return('🤡')
      allow(Face).to receive(:find_with_features).and_return(head: [0], mouth: [13])
      allow(Face).to receive(:find_with_layers).and_return('layers' => { 0 => 'head' })
      allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))

      emoji = described_class.new(params.merge(emoji_id: '1f921'))
      emoji.instance_variable_get(:@params)[:head] = 'not-an-emoji'

      expect do
        emoji.send(:validate_feature_param, :head)
      end.to raise_error(CustomTwemojiApiError, /Emoji is not valid/)
    end
  end

  describe '#label_layers_by_feature' do
    it 'raises when the SVG has fewer children than the layer model expects' do
      emoji = described_class.new(params)
      xml = Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')
      layers = { 0 => 'head', 1 => 'eyes' }

      expect do
        emoji.send(:label_layers_by_feature, xml, layers, '1f921')
      end.to raise_error(RuntimeError, /the number of layers in the model/)
    end
  end
end
