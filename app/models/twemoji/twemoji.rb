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

      xml = convert_children_paths_to_abs(xml)
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

  def replace_child(original_child, path_commands, xml)
    path_commands.each do |path_command|
      # Preserve the original
      new_child = original_child.dup
      new_child.attributes['d'].value = "M#{path_command}"

      xml.add_child(new_child)
    end

    xml
  end

  def convert_path_to_abs(node, xml)
    d = node.attributes['d'].value
    if d.nil?
      xml.add_child(node)
      return
    end

    abs_d = SvgPath.new(d).abs.to_s
    if abs_d == d
      xml.add_child(node)
      return
    end

    path_commands = abs_d.split('M').reject(&:empty?)

    if path_commands.length == 1
      node.attributes['d'].value = abs_d
      xml.add_child(node)
    else
      replace_child(node, path_commands, xml)
    end

    xml
  end

  def convert_children_paths_to_abs(xml)
    new_xml = xml.dup
    new_xml.children.map(&:remove)

    xml.children.each do |child|
      case child.name
      when 'g'
        fill = child.attributes['fill'].value unless child.attributes['fill'].nil?
        child.children.each do |grandchild|
          grandchild['fill'] = fill unless fill.nil?
          convert_path_to_abs(grandchild, new_xml)
        end
      when 'path'
        convert_path_to_abs(child, new_xml)
      else
        new_xml.add_child(child)
      end
    end

    new_xml
  end

  def subtract_layers(shape, hole)
    shape_path = shape.attributes['d'].value
    hole_path = hole.attributes['d'].value
    shape.attributes['d'].value = "#{shape_path} #{hole_path}"
    hole.remove
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
        when 'subtract'
          subtract_layers(xml.children[index - 1], xml.children[index])
          next
        when String
          feature = layers[index].to_sym
        when Hash
          feature = layers[index]['name'].to_sym
          fill = layers[index]['fill']
        end

        feature_name = "#{@id}-#{feature}"
        feature_number = features[feature].index(index)
        child[:id] = "#{feature_name}#{feature_number.zero? ? '' : feature_number.to_s}"
        child[:class] = feature_name
        child[:fill] = fill unless fill.nil?
      end
    end

    xml
  end
end
