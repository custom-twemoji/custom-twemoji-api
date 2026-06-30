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
  end
end
