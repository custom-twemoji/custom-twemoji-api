# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe AbsoluteTwemoji do
  let(:version) { '14.1.0' }
  let(:emoji_id) { '1f921' }
  let(:svg_body) do
    '<svg><path d="m0 0 l10 0"/></svg>'
  end

  before do
    stub_request(:get, %r{raw.githubusercontent.com/.+/#{emoji_id}\.svg})
      .to_return(status: 200, body: svg_body, headers: { 'Content-Type' => 'image/svg+xml' })
  end

  it 'converts relative path commands to absolute' do
    instance = described_class.new(version, emoji_id, remove_groups: false)
    expect(instance.xml.at('path').attributes['d'].value).to include('M0 0')
  end
end
