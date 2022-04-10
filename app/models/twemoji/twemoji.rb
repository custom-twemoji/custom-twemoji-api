# frozen_string_literal: true

require 'mini_magick'
require 'net/http'
require 'nokogiri'
require 'uri'

require_relative '../svgpath/svgpath'

# Defines an Twemoji
class Twemoji
  attr_reader :xml

  VALID_VERSIONS = %w[
    13.1.0
    13.1.1
    14.0.0
  ]

  def initialize(version, id, remove_groups)
    @id = id
    @version = version.nil? ? latest : version

    @github_url = build_github_url(@id)

    begin
      fetch_from_github(@github_url)
    rescue StandardError
      # Check for number representation input
      id = @id.to_i.to_s(16)
      github_url = build_github_url(id)
      fetch_from_github(github_url)
    end

    break_down_groups if remove_groups
  rescue StandardError => e
    raise "Failed to access SVG from GitHub: #{@github_url} | Error: #{e.message}"
  end

  def self.latest
    VALID_VERSIONS.last
  end

  def self.validate_version(version)
    case version
    when nil
      latest
    when *VALID_VERSIONS
      version
    else
      message = "Invalid Twemoji version: #{version} | Valid versions: #{VALID_VERSIONS.join(',')}"
      raise message
    end
  end

  private

  def build_github_url(id)
    'https://raw.githubusercontent.com/twitter/twemoji/'\
      "v#{@version}/assets/svg/#{id}.svg"
  end

  def fetch_from_github(github_url)
    response = Net::HTTP.get_response(URI.parse(github_url))

    case response
    when Net::HTTPSuccess
      @xml = Nokogiri::XML(response.body).css('svg')[0]
    else raise StandardError
    end
  end

  def break_down_group(node, xml)
    fill_attribute = node.attributes['fill']
    node_fill = fill_attribute.value if fill_attribute.present?

    node.children.each do |child|
      check_child_name_for_group(child, xml, node_fill)
    end
  end

  def check_child_name_for_group(child, xml, fill)
    case child.name
    when 'g'
      break_down_group(child, xml)
    else
      child[:fill] = fill unless fill.nil?
      xml.add_child(child)
    end
  end

  def break_down_groups
    no_groups_xml = @xml.dup
    no_groups_xml.children.map(&:remove)

    @xml.children.each do |child|
      check_child_name_for_group(child, no_groups_xml, nil)
    end

    @xml = no_groups_xml
  end
end
