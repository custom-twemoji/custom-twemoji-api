# frozen_string_literal: true

require 'mini_magick'
require 'net/http'
require 'nokogiri'
require 'uri'

require_relative '../svgpath/svgpath'

# Defines an Twemoji with absolute paths
class AbsoluteTwemoji < Twemoji
  attr_reader :xml

  def initialize(version, id)
    @version = version.nil? ? self.class.superclass.latest : version
    super(@version, id)

    @xml = analyze_children(@xml)
  end

  private

  def replace_child(original_child, path_commands, xml)
    path_commands.each do |path_command|
      # Preserve the original
      new_child = original_child.dup
      new_child.attributes['d'].value = "M#{path_command}"

      xml.add_child(new_child)
    end

    xml
  end

  def get_absolute_d(original_d, node, xml)
    if original_d.nil?
      xml.add_child(node)
      return
    end

    abs_d = SvgPath.new(original_d).abs.to_s
    if original_d == abs_d
      xml.add_child(node)
      return
    end

    abs_d
  end

  def convert_path_to_abs(node, xml)
    abs_d = get_absolute_d(node.attributes['d'].value, node, xml)
    return if abs_d.nil?

    path_commands = abs_d.split('M').reject(&:empty?)

    if path_commands.length == 1
      node.attributes['d'].value = abs_d
      xml.add_child(node)
    else
      replace_child(node, path_commands, xml)
    end

    xml
  end

  def break_down_group(node, xml)
    fill = node.attributes['fill'].value unless node.attributes['fill'].nil?
    node.children.each do |child|
      child['fill'] = fill unless fill.nil?
      analyze_child(child, xml)
    end
  end

  def analyze_child(child, xml)
    case child.name
    when 'g'
      break_down_group(child, xml)
    when 'path'
      convert_path_to_abs(child, xml)
    else
      xml.add_child(child)
    end
  end

  def analyze_children(xml)
    new_xml = xml.dup
    new_xml.children.map(&:remove)

    xml.children.each do |child|
      analyze_child(child, new_xml)
    end

    new_xml
  end
end
