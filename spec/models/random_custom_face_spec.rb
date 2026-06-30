# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe RandomCustomFace do
  let(:params) do
    {
      twemoji_version: '14.1.0',
      head: 'true',
      mouth: 'false',
      cheeks: 'false',
      nose: 'false',
      eyes: 'false',
      eyewear: 'false',
      headwear: 'false',
      other: 'false',
      background_color: 'transparent'
    }
  end

  before do
    allow(Face).to receive(:random).and_return('1f921' => {})
    allow(Face).to receive(:find_with_features).with('14.1.0', '1f921').and_return(head: [0])
    allow(Face).to receive(:find_with_layers).with('14.1.0', '1f921').and_return('layers' => { 0 => 'head' })
    allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))
  end

  describe '#initialize' do
    it 'creates a random custom face with random head emoji' do
      expect { described_class.new(params) }.not_to raise_error
    end
  end
end
