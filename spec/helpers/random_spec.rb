# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Random do
  describe '.check_float' do
    it 'parses floats between 0 and 1' do
      expect(described_class.check_float('0.5', :head)).to eq(0.5)
      expect(described_class.check_float('0', :head)).to eq(0.0)
      expect(described_class.check_float('1', :head)).to eq(1.0)
    end

    it 'returns nil for blank or non-numeric input' do
      expect(described_class.check_float(nil, :head)).to be_nil
      expect(described_class.check_float('', :head)).to be_nil
      expect(described_class.check_float('abc', :head)).to be_nil
    end

    it 'raises for values greater than one' do
      expect do
        described_class.check_float('1.5', :head)
      end.to raise_error(CustomTwemojiApiError, /not between 0 and 1/)
    end

    it 'raises for negative values' do
      expect do
        described_class.check_float('-0.5', :eyes)
      end.to raise_error(CustomTwemojiApiError, /not between 0 and 1/)
    end
  end

  describe '.from_hash' do
    it 'returns one of the hash keys' do
      hash = { 'a' => 1, 'b' => 2, 'c' => 3 }

      expect(hash.keys).to include(described_class.from_hash(hash))
    end
  end
end
