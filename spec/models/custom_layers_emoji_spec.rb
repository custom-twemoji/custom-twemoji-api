# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CustomLayersEmoji do
  let(:params) do
    {
      twemoji_version: '14.1.0',
      body: [],
      absolute_paths: 'false',
      remove_groups: 'false'
    }
  end

  before do
    allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))
    allow(Twemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))
    allow(Face).to receive(:find_with_layers).and_return('layers' => { 0 => 'head' })
  end

  describe '#to_s' do
    it 'returns an empty string when no body layers are provided' do
      emoji = described_class.new(params)
      expect(emoji.to_s).to eq('')
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
end
