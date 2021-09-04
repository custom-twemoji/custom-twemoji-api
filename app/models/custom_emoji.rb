# frozen_string_literal: true

require 'mini_magick'
require 'nokogiri'
require 'tempfile'
require "RMagick"
# require 'rsvg2'

require_relative 'twemoji/twemoji'
require_relative '../helpers/object'

# Defines an custom-built emoji
class CustomEmoji
  def initialize(params)
    @params = params
    @time = @params[:time]

    @size = @params[:size]
    @xml_template = xml_template

    @base_emoji_id = @params[:emoji_id]
    @twemoji_version = @params[:twemoji_version].presence || Twemoji.latest
  end

  def validate_emoji_input(input, find_class)
    return false if input == 'false'

    if input[0..1] == 'U+'
      input = input[2..]
    elsif input.scan(Unicode::Emoji::REGEX).length == 1
      # Source: https://dev.to/ohbarye/convert-emoji-and-codepoints-each-other-in-ruby-27j
      input = input.each_codepoint.map { |n| n.to_s(16) }
      input = input.join('-') if input.is_a?(Array)
    end

    find_class.find(input).nil? ? nil : input
  end

  def svg
    svg = Tempfile.new([to_s, '.svg'], 'tmp')

    File.open(svg.path, 'w') do |f|
      f.write(@xml)
    end

    svg
  end

  def png
    png_file = Tempfile.new([to_s, '.png'], 'tmp')
    svg_file = svg

    convert_svg_to_png(svg_file.path, png_file.path)
    # convert_svg_to_png(svg_file.path, png_file)
    contents = png_file.read

    png_file.unlink
    svg_file.unlink

    contents
  end

  private

  def xml_template
    xml = File.open('assets/template.svg') { |f| Nokogiri::XML(f) }.at(:svg)
    unless @size.nil?
      xml.attributes['width'].value = "#{@size}px"
      xml.attributes['height'].value = "#{@size}px"
    end

    xml
  end

  # Create a PNG file out of an SVG file
  def convert_svg_to_png(svg_filepath, png_filepath)
    density = @params[:density].presence
    size = @size.presence

    MiniMagick::Tool::Convert.new do |convert|
      convert.background('none')
      # convert.size("#{size}x#{size}")
      convert.resize("#{size}x#{size}") unless size.nil?

      convert.density(density) unless density.nil?
      convert << svg_filepath
      convert << png_filepath
    end
  end
end

    # convert = MiniMagick::Tool::Convert.new
    # convert.background('none')
    # convert.antialias.+
    # convert.size("#{size}x#{size}")
    # convert.density(density)
    # convert << svg_filepath
    # convert << png_filepath
    # convert.call

    # require 'pry'
    # binding.pry
    # puts 'end of pry'

    # img = Magick::Image.from_blob(@xml) {
    #   self.format = 'SVG'
    #   self.size = size unless size.nil?
    #   self.density = density
    #   self.background_color = 'transparent'
    # }
    # img[0].write(png_filepath)

    # image = MiniMagick::Image.open(svg_filepath)
    # image.resize("#{size}x#{size}")
    # image.format("png")
    # image.write(png_filepath)

    # svg = RSVG::Handle.new_from_data(@xml)
    # surface = Cairo::ImageSurface.new(Cairo::FORMAT_ARGB32, 800, 800)
    # context = Cairo::Context.new(surface)
    # context.render_rsvg_handle(svg)
    # b = StringIO.new
    # surface.write_to_png(b)
    # # t = ImageConvert.svg_to_png(f.read)
    # return b.string
