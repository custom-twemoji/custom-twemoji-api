# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Face do
  let(:version) { '14.1.0' }

  describe '.all' do
    it 'returns a hash of faces for the version' do
      faces = described_class.all(version)

      expect(faces).to be_a(Hash)
      expect(faces).to include('1f921')
    end

    it 'merges all nested version hashes' do
      faces = described_class.all('15.0.2')

      expect(faces).to be_a(Hash)
      expect(faces).to include('1fae8')
    end
  end

  describe '.layers_to_features' do
    it 'converts numeric layer hashes to feature symbols' do
      layers = { 0 => 'head', 1 => 'eyes', 2 => 'eyes', 3 => 'mouth' }
      features = described_class.layers_to_features(layers)

      expect(features).to eq(
        head: [0],
        eyes: [1, 2],
        mouth: [3]
      )
    end

    it 'returns nil for nil layers' do
      expect(described_class.layers_to_features(nil)).to be_nil
    end
  end

  describe '.find_with_layers' do
    it 'returns face data when the id exists' do
      face = described_class.find_with_layers(version, '1f921')

      expect(face).to be_a(Hash)
      expect(face).to include('glyph', 'layers')
    end

    it 'raises a custom error when the id is missing' do
      expect do
        described_class.find_with_layers(version, 'missing')
      end.to raise_error(CustomTwemojiApiError, /Emoji .* was not found/)
    end
  end

  describe '.find_with_glyph' do
    it 'returns the glyph for an id' do
      glyph = described_class.find_with_glyph(version, '1f921')

      expect(glyph).to eq('🤡')
    end
  end

  describe '.find_with_features' do
    it 'returns feature mapping for the id' do
      features = described_class.find_with_features(version, '1f921')

      expect(features[:head]).to include(0)
      expect(features[:cheeks]).to include(11, 12)
      expect(features[:mouth]).to include(13)
    end
  end

  describe '.random' do
    it 'returns a random face entry from the version data' do
      sample = described_class.random(version)

      expect(sample.keys.size).to eq(1)
      expect(sample.values.first).to be_a(Hash)
    end
  end
end
