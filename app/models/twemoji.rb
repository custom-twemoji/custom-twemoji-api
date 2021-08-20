# frozen_string_literal: true

require 'mini_magick'
require 'net/http'
require 'nokogiri'
require 'uri'
require 'yaml'

# Defines an Twemoji
class Twemoji
  attr_reader :xml

  DEFAULT_VERSION = '13.1.0'

  def initialize(version, id)
    version = DEFAULT_VERSION if version.nil?
    @github_url = build_github_url(version, id)
    response = Net::HTTP.get_response(URI.parse(@github_url))

    case response
    when Net::HTTPSuccess
      @xml = Nokogiri::XML(response.body).css('svg')[0]
    else raise
    end
  rescue StandardError => e
    raise "Failed to access SVG from GitHub: #{@github_url} | Error: #{e.message}"
  end

  private

  def build_github_url(version, id)
    'https://raw.githubusercontent.com/twitter/twemoji/'\
    "v#{version}/assets/svg/#{id}.svg"
  end
end
