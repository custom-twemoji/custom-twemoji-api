# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe SvgPath do
  describe '#abs' do
    it 'converts relative coordinates to absolute' do
      path = 'm10 10 l10 0 l0 10'
      svg_path = described_class.new(path)

      expect(svg_path.abs).to be_a(described_class)
      expect(svg_path.to_s).to include('M10 10L20 10 20 20')
    end

    it 'converts relative arc commands to absolute coordinates' do
      path = 'm0 0 a10 10 0 0 1 10 0'
      svg_path = described_class.new(path)

      expect(svg_path.abs).to be_a(described_class)
      expect(svg_path.to_s).to include('A')
    end

    it 'converts horizontal and vertical relative commands' do
      path = 'm0 0 h10 v10'
      svg_path = described_class.new(path)

      expect(svg_path.abs.to_s).to include('M0 0H10V10')
    end

    it 'reports parse errors for invalid path data' do
      svg_path = described_class.new('M0 0 A10 10 0 2 1 10 0')

      expect(svg_path.err).to include('arc flag can be 0 or 1 only')
    end
  end

  describe '#to_s' do
    it 'formats path output without repeated command names' do
      path = 'M0 0 L10 0 L10 10'
      svg_path = described_class.new(path)

      expect(svg_path.to_s).to eq('M0 0L10 0 10 10')
    end
  end
end

RSpec.describe Ellipse do
  describe '#transform' do
    it 'treats a circle transform as a circle and resets the angle' do
      ellipse = described_class.new(10, 10, 0)
      result = ellipse.transform([1, 0, 0, 1, 0, 0])

      expect(result).to be_a(described_class)
      expect(result.isDegenerate).to be false
    end

    it 'changes rotation for a non-circle transform matrix' do
      ellipse = described_class.new(10, 20, 30)
      result = ellipse.transform([2, 0, 0, 1, 0, 0])

      expect(result).to be_a(described_class)
      expect(result.instance_variable_get(:@ax)).not_to eq(30)
    end
  end
end
