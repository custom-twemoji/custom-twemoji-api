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

  it "preserves 'V' segments when the matrix only translates" do
    svg = SvgPath.new('M0 0 V10')
    svg.stack << [1, 0, 0, 1, 0, 5]

    svg.send(:evaluateStack)

    expect(svg.segments[1][0]).to eq('V')
    expect(svg.segments[1][1]).to be_within(0.01).of(15.0)
  end

  it "preserves 'H' segments when the matrix only translates" do
    svg = SvgPath.new('M0 0 H10')
    svg.stack << [1, 0, 0, 1, 0, 5]

    svg.send(:evaluateStack)

    expect(svg.segments[1][0]).to eq('H')
    expect(svg.segments[1][1]).to be_within(0.01).of(10.0)
  end

  it 'flips the arc sweep flag when the matrix flips orientation' do
    svg = SvgPath.new('M0 0 a5 5 0 0 1 5 5')
    svg.stack << [1, 0, 0, -1, 0, 0]

    svg.send(:evaluateStack)

    expect(svg.segments[1][0]).to eq('a')
    expect(svg.segments[1][5]).to eq('0')
  end

  it 'replaces a degenerate arc with a line' do
    svg = SvgPath.new('M0 0 a5 5 0 0 1 5 5')
    # matrix collapses one axis so the transformed ellipse degenerates
    svg.stack << [1, 0, 0, 0, 0, 0]

    svg.send(:evaluateStack)

    expect(svg.segments[1][0]).to(satisfy { |v| %w[l L].include?(v) })
  end

  it 'processes relative m segments without applying translation' do
    svg = SvgPath.new('M0 0 m5 5')
    svg.stack << [1, 0, 0, 1, 1, 1]

    svg.send(:evaluateStack)

    expect(svg.segments[1][0]).to eq('m')
    expect(svg.segments[1][1]).to be_within(0.01).of(5.0)
    expect(svg.segments[1][2]).to be_within(0.01).of(5.0)
  end

  it 'resets the contour start for z segments during transforms' do
    svg = SvgPath.new('M0 0 l5 5 z')
    svg.stack << [1, 0, 0, 1, 1, 0]

    svg.send(:evaluateStack)

    expect(svg.segments.length).to eq(3)
    expect(svg.segments.last[0]).to eq('z')
  end
end
