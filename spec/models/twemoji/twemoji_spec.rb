# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe Twemoji do
  let(:version) { '14.1.0' }
  let(:emoji_id) { '1f921' }
  let(:svg_body) do
    '<svg><g><path d="M0 0 L10 0"/></g></svg>'
  end

  before do
    stub_request(:get, %r{raw.githubusercontent.com/.+/#{emoji_id}\.svg})
      .to_return(status: 200, body: svg_body, headers: { 'Content-Type' => 'image/svg+xml' })
  end

  describe '.latest' do
    it 'returns the first valid version from the fixture' do
      expect(described_class.latest).not_to be_nil
    end
  end

  describe '.validate_version' do
    it 'returns the version when it is valid' do
      expect(described_class.validate_version(version)).to eq(version)
    end

    it 'raises on invalid version' do
      expect do
        described_class.validate_version('invalid')
      end.to raise_error(CustomTwemojiApiError, /Invalid twemoji_version parameter/)
    end
  end

  describe '#initialize' do
    it 'fetches SVG from GitHub and sets xml' do
      subject = described_class.new(version, emoji_id, false)
      expect(subject.xml.name).to eq('svg')
    end

    it 'retries using integer codepoint when initial fetch fails' do
      stub_request(:get, %r{raw.githubusercontent.com/.+/#{emoji_id}\.svg})
        .to_return(status: 500)
      integer_id = emoji_id.to_i.to_s(16)
      stub_request(:get, %r{raw.githubusercontent.com/.+/#{integer_id}\.svg})
        .to_return(status: 200, body: svg_body)

      expect(described_class.new(version, emoji_id, false).xml.name).to eq('svg')
    end
  end

  describe '#break_down_groups' do
    it 'removes group wrappers when remove_groups is true' do
      grouped_svg = '<svg><g><path d="M0 0 L10 0"/></g></svg>'
      stub_request(:get, %r{raw.githubusercontent.com/.+/#{emoji_id}\.svg})
        .to_return(status: 200, body: grouped_svg)

      instance = described_class.new(version, emoji_id, true)
      expect(instance.xml.at('path')).not_to be_nil
    end
  end
end
