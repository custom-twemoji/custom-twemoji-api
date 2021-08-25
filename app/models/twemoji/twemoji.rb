# frozen_string_literal: true

require 'mini_magick'
require 'net/http'
require 'nokogiri'
require 'uri'

require_relative '../svgpath/svgpath'

# Defines an Twemoji
class Twemoji
  attr_reader :xml

  def initialize(version, id, layers, features, raw)
    @id = id
    @version = version.nil? ? latest : version
    @github_url = build_github_url
    response = Net::HTTP.get_response(URI.parse(@github_url))

    case response
    when Net::HTTPSuccess
      xml = Nokogiri::XML(response.body).css('svg')[0]

      xml = convert_to_absolute_commands(xml)
      xml = label_layers_by_feature(xml, layers, features) unless raw == true

      @xml = xml
    else raise
    end
  rescue StandardError => e
    raise "Failed to access SVG from GitHub: #{@github_url} | Error: #{e.message}"
  end

  def self.latest
    '13.1.0'
  end

  private

  def build_github_url
    'https://raw.githubusercontent.com/twitter/twemoji/'\
    "v#{@version}/assets/svg/#{@id}.svg"
  end

  def convert_to_absolute_commands(xml)
    xml.children.each_with_index do |child, _index|
      next unless child.name == 'path'

      d = child.attributes['d'].value
      next if d.nil?

      abs_d = SvgPath.new(d).abs.to_s

      next unless abs_d != d

      path_commands = abs_d.split('M').reject(&:empty?)

      if path_commands.length == 1
        child.attributes['d'].value = abs_d
      else
        child_dup = child.dup
        child.remove

        path_commands.each do |path_command|
          new_child = child_dup.dup
          new_child.attributes['d'].value = "M#{path_command}"

          xml.add_child(new_child)
        end
      end
    end

    xml
  end

  def label_layers_by_feature(xml, layers, features)
    xml.children.each_with_index do |child, index|
      if layers[index].nil?
        message = "Found missing layer data | emoji: #{@id} , layer: #{index} , xml: #{child}"
        raise NameError, message
      else
        feature = nil
        fill = nil

        case layers[index]
        when String
          feature = layers[index].to_sym
        when Hash
          feature = layers[index]['name'].to_sym
          fill = layers[index]['fill']
        end

        feature_number = features[feature].index(index)

        child[:id] = feature.to_s << (feature_number.zero? ? '' : feature_number.to_s)
        child[:class] = feature
        child[:fill] = fill unless fill.nil?
      end
    end

    xml
  end
end
