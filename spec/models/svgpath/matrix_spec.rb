# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../app/models/svgpath/svgpath'

RSpec.describe 'SvgPath matrix transforms' do
  it 'applies translate matrix from stack to coordinates' do
    svg = SvgPath.new('M0 0 L10 0')

    # push a translate +10 on x
    svg.stack << [1, 0, 0, 1, 10, 0]

    # run evaluation and inspect segments
    svg.send(:evaluateStack)
    expect(svg.segments).to all(be_a(Array))

    str = svg.to_s
    expect(str).to include('M10 0')
    expect(str).to include('L20 0')
  end

  it 'applies multiple stacked matrices in reverse order' do
    svg = SvgPath.new('M0 0 L1 0')

    # two translations: +2 then +3 -> net +5
    svg.stack << [1, 0, 0, 1, 2, 0]
    svg.stack << [1, 0, 0, 1, 3, 0]

    svg.send(:evaluateStack)
    expect(svg.segments).to all(be_a(Array))

    str = svg.to_s
    expect(str).to include('M5 0')
    expect(str).to include('L6 0')
  end
end
