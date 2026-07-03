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

    it 'produces binary data using ImageMagick' do
      emoji = described_class.new(params.merge(renderer: 'imagemagick', size: 16))
      # ensure xml is present
      emoji.instance_variable_set(:@xml, Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>'))

      # Stub MiniMagick::Tool::Convert to write PNG to provided path
      convert_double = double('convert')
      allow(MiniMagick::Tool::Convert).to receive(:new).and_yield(convert_double)
      allow(convert_double).to receive(:background)
      allow(convert_double).to receive(:size)
      allow(convert_double).to receive(:<<) do |arg|
        # when called with the output path, write sample PNG bytes
        if arg.to_s.end_with?('.png')
          File.write(arg, "PNG-BYTES")
        end
      end

      result = emoji.png('imagemagick', 'nonce')
      expect(result).to include('PNG-BYTES')
    end
  end

  describe '#svg and #xml_template' do
    it 'returns a Tempfile for svg and honors size/background' do
      e = described_class.new(params.merge(size: '64', background_color: '#abcdef'))
      # ensure @xml is set so #svg writes content
      e.instance_variable_set(:@xml, e.instance_variable_get(:@xml_template))
      svg_file = e.svg

      expect(svg_file).to be_a(Tempfile)
      contents = File.read(svg_file.path)
      expect(contents).to include('<svg')
      svg_file.unlink
    end

    it 'xml_template applies provided size and background color' do
      e = described_class.allocate
      e.instance_variable_set(:@size, '32')
      e.instance_variable_set(:@background_color, '#010203')
      e.instance_variable_set(:@padding, 0)
      xml = e.send(:xml_template)

      expect(xml.attributes['width'].value).to include('32')
      expect(xml.css('rect').first.attributes['fill'].value).to eq('#010203')
    end
    end
  end
