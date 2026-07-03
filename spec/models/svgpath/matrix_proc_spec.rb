# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../app/models/svgpath/svgpath'

RSpec.describe 'SvgPath matrix_proc branches' do
  it "converts 'v' to a line when matrix produces non-zero x component" do
    svg = SvgPath.new('M0 0 v10')
    # matrix that maps (0,10) -> (10,10)
    svg.stack << [0, 0, 1, 1, 0, 0]

    svg.send(:evaluateStack)

    expect(svg.segments[1][0]).to(satisfy { |v| %w[l L].include?(v) })
    expect(svg.segments[1][1]).to be_within(0.01).of(10.0)
    expect(svg.segments[1][2]).to be_within(0.01).of(10.0)
  end

  it "converts 'h' to a line when matrix produces non-zero y component" do
    svg = SvgPath.new('M0 0 h10')
    # matrix that maps (10,0) -> (10,10)
    svg.stack << [1, 0, 0, 1, 0, 0]
    # but we need a matrix with m[1] or m[3] to produce non-zero y; use [1,1,0,1,...]
    svg.stack << [1, 1, 0, 1, 0, 0]

    svg.send(:evaluateStack)

    expect(svg.segments[1][0]).to(satisfy { |v| %w[l L].include?(v) })
    expect(svg.segments[1][1]).to be_within(0.01).of(10.0).or be_within(0.01).of(10.0)
  end

  it 'replaces empty arc with a line when endpoint equals start' do
    svg = SvgPath.new('m0 0 a10 10 0 0 1 0 0')
    # push a trivial transform so matrix processing runs
    svg.stack << [1, 0, 0, 1, 1, 0]

    svg.send(:evaluateStack)

    # arc should have been replaced with line
    seg = svg.segments[1]
    expect(seg[0]).to(satisfy { |v| %w[l L].include?(v) })
    expect(seg[1]).to be_a(Numeric)
    expect(seg[2]).to be_a(Numeric)
  end
end
