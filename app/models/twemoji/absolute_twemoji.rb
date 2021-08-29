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
    @version = version.nil? ? self.class.superclass.latest : version
    super(@version, id, features)

    @xml = analyze_children(@xml)
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

  def subtract_layers(shape, hole)
    shape.attributes['d'].value = "#{shape.attributes['d'].value} #{hole.attributes['d'].value}"
    hole[:class] = 'hole'
    nil
  end

  def find_layer_underneath(layers, current_index, xml)
    (current_index - 1).downto(0) do |i|
      return xml.children[i] unless ['', 'subtract'].include?(layers[i])
    end

    raise "No bottom layer to subtract with layer #{current_index}"
  end

  def determine_layer_format(layers, index, xml)
    case layers[index]
    when 'subtract'
      subtract_layers(find_layer_underneath(layers, index, xml), xml.children[index])
    when String
      [
        layers[index].to_sym,
        nil
      ]
    when Hash
      [
        layers[index]['name'].to_sym,
        layers[index]['fill']
      ]
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
    if layers[index].nil?
      message = "Found missing layer data | emoji: #{@id} , layer: #{index} , xml: #{node}"
      raise NameError, message
    else
      feature, fill = determine_layer_format(layers, index, xml)
      update_node_attributes(node, feature, index, fill) unless feature.nil?
    end
  end

  def label_layers_by_feature(xml, layers)
    xml.children.each_with_index do |child, index|
      label_layers_of_feature(xml, layers, child, index)
    end

    if xml.children.length < layers.length
      raise "Number of layers in the model (#{layers.length}) greater"\
        " than the number in the SVG (#{xml.children.length})"
    end

    xml.css("[class='hole']").each(&:remove)
    xml
  end
end
