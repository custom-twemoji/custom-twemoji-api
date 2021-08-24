# frozen_string_literal: true

require 'mini_magick'
require 'nokogiri'
require 'tempfile'

require_relative 'twemoji/twemoji'
require_relative '../helpers/object'

# Defines an custom-built emoji
class CustomEmoji
  def initialize(params)
    @params = params
    @time = @params[:time]
    @emoji_id = @params[:emoji_id]
    @xml_template = File.open('assets/template.svg') { |f| Nokogiri::XML(f) }.at(:svg)
    @twemoji_version = @params[:twemoji_version].presence || Twemoji.latest
  end

  def svg
    svg = Tempfile.new([to_s, '.xvg'], 'tmp')

    File.open(svg.path, 'w') do |f|
      f.write(a)
    end

    svg
  end

  def png
    png_file = Tempfile.new([to_s, '.png'], 'tmp')
    svg_file = svg

    convert_svg_to_png(svg_file.path, png_file.path)
    contents = png_file.read

    png_file.unlink
    svg_file.unlink

    contents
  end

  private

  # Adds a layer of a Twemoji's XML to an XML template
  # def add_layer(twemoji_xml, layer_number)
  #   # Duplicate or else it will be removed from the original file
  #   layer = twemoji_xml.children[layer_number].dup
  #   @xml_template.add_child(layer)
  # end

  # def add_multiple_layers(twemoji_xml, layers)
  #   layers.each do |layer|
  #     raise NameError, "Found invalid layer data: #{layer}" unless layer.is_a?(Integer)

  #     add_layer(twemoji_xml, layer)
  #   end
  # end

  # Adds all layers for a feature to an XML template
  # def add_all_feature_layers(layers)
  #   layers.each do |layer|
  #     @xml_template.add_child(layer)
  #   end

  #   # case layers
  #   # when Integer
  #   #   # Feature is an integer corresponding to only one layer
  #   #   add_layer(twemoji_xml, layers)
  #   # when Array
  #   #   # Feature is an array corresponding to more than one layer
  #   #   add_multiple_layers(twemoji_xml, layers)
  #   # when nil
  #   # else raise NameError, "Found invalid layers data: #{layers}"
  #   # end
  # end

  # Create a PNG file out of an SVG file
  def convert_svg_to_png(svg_filepath, png_filepath)
    MiniMagick::Tool::Convert.new do |convert|
      convert.background('none')
      convert.size('37x37')
      convert << svg_filepath
      convert << png_filepath
    end
  end
end
