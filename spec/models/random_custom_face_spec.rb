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

    it 'randomizes a feature when no param is given and the feature is the head' do
      params[:head] = nil

      face = described_class.new(params)

      expect(face.instance_variable_get(:@params)[:head]).to eq('1f921')
    end

    it 'honors a float chance for non-head features' do
      params[:mouth] = '0.2'
      allow(Face).to receive(:find_with_features).and_return(head: [0], mouth: [13])
      allow_any_instance_of(described_class).to receive(:rand).and_return(0.0)

      face = described_class.new(params)

      expect(face.instance_variable_get(:@params)[:mouth]).not_to be_nil
    end
  end

  describe '#valid_float?' do
    it 'returns true for a numeric string' do
      expect(described_class.new(params).send(:valid_float?, '0.5')).to be true
    end

    it 'returns false for a non-numeric string' do
      expect(described_class.new(params).send(:valid_float?, 'abc')).to be false
    end
  end
end
