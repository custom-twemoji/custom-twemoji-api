# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe MashupCustomFace do
  let(:params) do
    {
      twemoji_version: '14.1.0',
      emojis: '1f600,1f603',
      amount: 2,
      use_every_feature: 'true'
    }
  end

  before do
    allow(Twemoji).to receive(:validate_version).and_return('14.1.0')
    allow(Face).to receive(:find_with_features).and_return(head: ['1f600'], mouth: ['1f603'])
    allow(Face).to receive(:find_with_layers).and_return('layers' => { 0 => 'head' })
    allow(Face).to receive(:random).and_return({ '1f600' => {} })
    allow(AbsoluteTwemoji).to receive(:new).and_return(double(xml: Nokogiri::XML('<svg><path d="M0 0 L10 0"/></svg>').at('svg')))
  end

  describe '#initialize' do
    it 'raises when amount is less than required faces' do
      params[:amount] = 1

      expect do
        described_class.new(params)
      end.to raise_error(CustomTwemojiApiError, /Amount parameter on mashup should be greater than one/)
    end

    it 'raises when amount exceeds supported faces' do
      allow(Face).to receive(:all).and_return('1f600' => {}, '1f603' => {})
      params[:amount] = 10

      expect do
        described_class.new(params)
      end.to raise_error(CustomTwemojiApiError, /Amount parameter \(10\) exceeds number of supported faces/)
    end

    it 'builds a mashup when amount matches or exceeds emojis count' do
      expect do
        described_class.new(params)
      end.not_to raise_error
    end
  end
end
