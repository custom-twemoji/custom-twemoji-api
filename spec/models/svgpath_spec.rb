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
  end

  describe '#to_s' do
    it 'formats path output without repeated command names' do
      path = 'M0 0 L10 0 L10 10'
      svg_path = described_class.new(path)

      expect(svg_path.to_s).to eq('M0 0L10 0 10 10')
    end
  end
end
