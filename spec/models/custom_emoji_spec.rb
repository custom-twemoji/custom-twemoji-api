# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe CustomEmoji do
  let(:params) do
    {
      twemoji_version: '14.1.0',
      emoji_id: '1f921',
      renderer: 'imagemagick',
      background_color: 'transparent'
    }
  end

  let(:emoji) { described_class.new(params) }

  describe '#validate_emoji_input' do
    it 'accepts unicode codepoint strings' do
      expect(emoji.validate_emoji_input('U+1F921')).to eq('1f921')
    end

    it 'rejects invalid emoji values' do
      expect do
        emoji.validate_emoji_input('invalid')
      end.to raise_error(CustomTwemojiApiError)
    end
  end

  describe '#get_resource_in_file_format' do
    it 'returns svg path when format is svg' do
      emoji = described_class.new(params.merge(size: 64))
      expect(emoji.get_resource_in_file_format('svg')).to be_a(Tempfile)
    end
  end

  describe '#update_padding' do
    it 'raises if padding is too large' do
      emoji = described_class.allocate
      emoji.instance_variable_set(:@size, 64)
      emoji.instance_variable_set(:@padding, 34)
      emoji.instance_variable_set(:@xml_template, Nokogiri::XML(File.read('assets/template.svg')).at(:svg))

      expect do
        emoji.send(:update_padding, emoji.instance_variable_get(:@xml_template), 20)
      end.to raise_error(CustomTwemojiApiError, /Padding must be less than half of the size/)
    end
  end

  describe '#png' do
    let(:png_params) { params.merge(size: 32, renderer: 'canvg') }

    it 'returns HTML content for canvg renderer' do
      emoji = described_class.new(png_params)
      svg_xml = Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>')
      emoji.instance_variable_set(:@xml, svg_xml)

      result = emoji.png('canvg', 'nonce123')
      expect(result).to include('<!doctype html>')
      expect(result).to include('Canvg.fromString')
      expect(result).to include('nonce123')
    end

    it 'raises for unsupported renderers' do
      emoji = described_class.new(params.merge(renderer: 'unknown'))
      emoji.instance_variable_set(:@xml, Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>'))

      expect do
        emoji.png('unknown', 'nonce')
      end.to raise_error(CustomTwemojiApiError, /Renderer not supported/)
    end
  end
end
