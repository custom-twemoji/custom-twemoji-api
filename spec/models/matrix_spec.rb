# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Matrix do
  describe '#translate' do
    it 'translates a point by the given values' do
      matrix = described_class.new.translate(10, 20)

      expect(matrix.calc(1, 2, false)).to eq([11, 22])
    end
  end

  describe '#scale' do
    it 'scales a point by the given factors' do
      matrix = described_class.new.scale(2, 3)

      expect(matrix.calc(1, 2, false)).to eq([2, 6])
    end
  end

  describe '#rotate' do
    it 'rotates a point around an origin' do
      matrix = described_class.new.rotate(90, 0, 0)

      expect(matrix.calc(1, 0, false).map { |v| v.round(6) }).to eq([0.0, 1.0])
    end
  end

  describe '#skewX and #skewY' do
    it 'skews points across axes' do
      matrix = described_class.new.skewX(45).skewY(45)

      expect(matrix.toArray).to be_a(Array)
      expect(matrix.calc(1, 1, false).length).to eq(2)
    end
  end
end
