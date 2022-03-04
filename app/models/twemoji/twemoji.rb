# frozen_string_literal: true

require 'mini_magick'
require 'net/http'
require 'nokogiri'
require 'uri'

require_relative '../svgpath/svgpath'

# Defines an Twemoji
class Twemoji
  attr_reader :xml

  def initialize(version, id, raw = false)
    @id = id
    @version = version.nil? ? latest : version
    @github_url = build_github_url

    fetch_from_github
    break_down_groups unless raw
  rescue StandardError => e
    raise "Failed to access SVG from GitHub: #{@github_url} | Error: #{e.message}"
  end

  def self.latest
    '13.1.0'
  end

  def self.validate_version(version)
    case version
    when nil
      latest
    when '13.1.0'
      version
    else
      message = "Invalid Twemoji version: #{version} | Valid versions: 13.1.0"
      raise message
    end
  end

  private

  def build_github_url
    'https://raw.githubusercontent.com/twitter/twemoji/'\
      "v#{@version}/assets/svg/#{@id}.svg"
  end

  def fetch_from_github
    response = Net::HTTP.get_response(URI.parse(@github_url))

    case response
    when Net::HTTPSuccess
      @xml = Nokogiri::XML(response.body).css('svg')[0]
    else raise
    end
  end

  def break_down_group(node, xml)
    node.children.each do |child|
      analyze_child(child, xml)
    end
  end

  def analyze_child(child, xml)
    case child.name
    when 'g'
      break_down_group(child, xml)
    else
      xml.add_child(child)
    end
  end

  def break_down_groups
    no_groups_xml = @xml.dup
    no_groups_xml.children.map(&:remove)

    xml.children.each do |child|
      analyze_child(child, no_groups_xml)
    end

    @xml = no_groups_xml
  end
end
