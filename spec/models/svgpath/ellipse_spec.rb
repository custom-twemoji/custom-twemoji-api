# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../app/models/svgpath/ellipse'

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
