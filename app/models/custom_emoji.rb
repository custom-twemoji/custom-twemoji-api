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

  def validate_emoji_input(input, find_class)
    if input[0..1] == 'U+'
      # String with U+
      input = input[2..]
    elsif input.length == 1 && input.scan(Unicode::Emoji::REGEX).length == 1
      # Emoji
      input = input.each_codepoint.map { |n| n.to_s(16) }[0]
    end

    find_class.find(input).nil? ? nil : input
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
