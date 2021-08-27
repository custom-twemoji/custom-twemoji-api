# frozen_string_literal: true

require 'mini_magick'
require 'net/http'
require 'nokogiri'
require 'uri'

require_relative '../svgpath/svgpath'

# Defines an Twemoji with absolute paths
class AbsoluteTwemoji < Twemoji
  attr_reader :xml

  def initialize(version, id, layers, features, raw)
    super(version, id, features)

    @xml = convert_children_paths_to_abs(@xml)
    @xml = label_layers_by_feature(@xml, layers) unless raw == true
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

  def convert_d_to_abs(node, xml)
    fill = node.attributes['fill'].value unless node.attributes['fill'].nil?
    node.children.each do |child|
      child['fill'] = fill unless fill.nil?
      convert_path_to_abs(child, xml)
    end
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

  def convert_child_to_abs(child, xml)
    case child.name
    when 'g'
      convert_d_to_abs(child, xml)
    when 'path'
      convert_path_to_abs(child, xml)
    else
      xml.add_child(child)
    end
  end

  def convert_children_paths_to_abs(xml)
    new_xml = xml.dup
    new_xml.children.map(&:remove)

    xml.children.each do |child|
      convert_child_to_abs(child, new_xml)
    end

    new_xml
  end

  def subtract_layers(shape, hole)
    shape.attributes['d'].value = "#{shape.attributes['d'].value} #{hole.attributes['d'].value}"
    hole.remove
  end

  def determine_layer_format(layers, index, xml)
    case layers[index]
    when 'subtract'
      subtract_layers(xml.children[index - 1], xml.children[index])
    when String
      [layers[index].to_sym, nil]
    when Hash
      [layers[index]['name'].to_sym, layers[index]['fill']]
    end
  end

  def update_node_attributes(node, feature, index, fill)
    feature_name = "#{@id}-#{feature}"
    feature_number = @features[feature].index(index)
    node[:id] = "#{feature_name}#{feature_number.zero? ? '' : feature_number.to_s}"
    node[:class] = feature_name
    node[:fill] = fill unless fill.nil?
  end

  def label_layers_of_feature(xml, layers, node, index)
    feature, fill = determine_layer_format(layers, index, xml)
    update_node_attributes(node, feature, index, fill)
  end

  def label_layers_by_feature(xml, layers)
    xml.children.each_with_index do |child, index|
      if layers[index].nil?
        message = "Found missing layer data | emoji: #{@id} , layer: #{index} , xml: #{child}"
        raise NameError, message
      else
        label_layers_of_feature(xml, layers, child, index)
      end
    end

    xml
  end
end
