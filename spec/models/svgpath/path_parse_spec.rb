# frozen_string_literal: true

require_relative '../../spec_helper'
require_relative '../../../app/models/svgpath/path_parse'

RSpec.describe 'pathParse' do
  it 'parses simple move and line commands' do
    result = pathParse('M10 10 L20 20')

    expect(result[:err]).to eq('')
    expect(result[:segments]).to be_an(Array)
    expect(result[:segments].first[0]).to eq('M')
  end

  it 'returns error when path does not start with M or m' do
    result = pathParse('l10 10')

    expect(result[:err]).to include('string should start with')
    expect(result[:segments]).to eq([])
  end

  it 'parses decimal and exponent numbers' do
    result = pathParse('M0 0 L1.5e2 2')

    expect(result[:err]).to eq('')
    expect(result[:segments].last[1]).to be_a(Float)
  end

  it 'parses implicit lineto parameters after a move command' do
    result = pathParse('M10 10 20 20')

    expect(result[:err]).to eq('')
    expect(result[:segments]).to eq([
      ['M', 10.0, 10.0],
      ['L', 20.0, 20.0]
    ])
  end

  it 'parses lowercase move and expands to relative lineto' do
    result = pathParse('m10 10 20 20')

    expect(result[:err]).to eq('')
    expect(result[:segments]).to eq([
      ['M', 10.0, 10.0],
      ['l', 20.0, 20.0]
    ])
  end

  it 'parses a closepath command' do
    result = pathParse('M0 0 Z')

    expect(result[:err]).to eq('')
    expect(result[:segments].last[0]).to eq('Z')
    expect(result[:segments].last.size).to eq(1)
  end

  it 'parses relative r commands without splitting parameters' do
    result = pathParse('M0 0 r10 10 20 20')

    expect(result[:err]).to eq('')
    expect(result[:segments].last).to eq(['r', 10.0, 10.0, 20.0, 20.0])
  end

  it 'returns error when path contains an invalid command' do
    result = pathParse('M0 0 X10 10')

    expect(result[:err]).to include('bad command')
    expect(result[:segments]).to eq([])
  end

  it 'returns error when an arc flag is invalid' do
    result = pathParse('M0 0 A1 1 0 2 0 10 10')

    expect(result[:err]).to include('arc flag can be 0 or 1 only')
    expect(result[:segments]).to eq([])
  end

  it 'returns error when a parameter is missing' do
    result = pathParse('M0 0 L10')

    expect(result[:err]).to include('missed param')
    expect(result[:segments]).to eq([])
  end

  it 'returns error for invalid float exponent syntax' do
    result = pathParse('M0 0 L.e2 10')

    expect(result[:err]).to include('invalid float exponent')
    expect(result[:segments]).to eq([])
  end

  it 'errors on numbers with leading zero like 09' do
    result = pathParse('M0 0 L09 1')

    expect(result[:err]).to include('numbers started with `0`')
    expect(result[:segments]).to eq([])
  end
end
