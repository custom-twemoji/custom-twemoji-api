# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CustomFace do
  describe '#determine_layer_format' do
    let(:emoji) do
      described_class.allocate.tap do |instance|
        instance.instance_variable_set(:@params, {})
        instance.instance_variable_set(:@twemoji_version, '14.1.0')
      end
    end

    it 'returns correct symbol and nil fill for string layer values' do
      xml = Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')
      feature, fill = emoji.send(:determine_layer_format, ['head'], 0, xml)

      expect(feature).to eq(:head)
      expect(fill).to be_nil
    end

    it 'handles layer values with fill hashes' do
      xml = Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')
      feature, fill = emoji.send(:determine_layer_format, [{ 'name' => 'head', 'fill' => 'red' }], 0, xml)

      expect(feature).to eq(:head)
      expect(fill).to eq('red')
    end
  end
end
