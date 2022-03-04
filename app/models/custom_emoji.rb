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

    @size = @params[:size].presence
    @padding = (@params[:padding].presence || 0).to_s.delete('px').to_i
    @renderer = @params[:renderer]
    @background_color = @params[:background_color]

    @xml_template = xml_template

    @twemoji_version = Twemoji.validate_version(@params[:twemoji_version])
  end

  def check_number_representation(find_class, find_function, emoji_input, error_message, exclude_groups)
    emoji_input = emoji_input.to_i.to_s(16)

    begin
      if find_class.send(find_function, @twemoji_version, emoji_input, exclude_groups).nil?
        raise error_message
      end
    rescue
      raise error_message
    end

    emoji_input
  end

  def validate_emoji_input(emoji_input, find_class, find_function, exclude_groups)
    return false if emoji_input == 'false'

    message = "Emoji is not supported: #{emoji_input}"
    emoji_input = emoji_input.downcase

    if emoji_input[0..1] == 'u+'
      emoji_input = emoji_input[2..]
    elsif emoji_input.scan(Unicode::Emoji::REGEX).length == 1
      # Source: https://dev.to/ohbarye/convert-emoji-and-codepoints-each-other-in-ruby-27j
      emoji_input = emoji_input.each_codepoint.map { |n| n.to_s(16) }
      emoji_input = emoji_input.join('-') if emoji_input.is_a?(Array)
    end

    begin
      # Check for number representation if nil
      if find_class.send(find_function, @twemoji_version, emoji_input, exclude_groups).nil?
        emoji_input = check_number_representation(
          find_class,
          find_function,
          emoji_input,
          message,
          exclude_groups
        )
      end
    rescue
      # Check for number representation if error occurred
      emoji_input = check_number_representation(
        find_class,
        find_function,
        emoji_input,
        message,
        exclude_groups
      )
    end

    emoji_input
  end

  def svg
    svg = Tempfile.new([to_s, '.svg'], 'tmp')

    File.open(svg.path, 'w') do |f|
      f.write(@xml)
    end

    svg
  end

  def png(renderer)
    size = @size.presence || 128
    renderer = @renderer.presence || renderer

    svg_xml = Nokogiri::XML(@xml)
    svg_xml.at(:svg).attributes['width'].value = "#{size}px"
    svg_xml.at(:svg).attributes['height'].value = "#{size}px"

    update_padding(svg_xml, 128) if @padding.presence

    case renderer.downcase
    when 'canvg'
      canvg(svg_xml)
    when 'imagemagick'
      imagemagick
    else
      message = "Renderer not supported: #{@renderer} | Valid renderers: canvg, imagemagick"
      raise message
    end
  end

  private

  def xml_template
    xml = File.open('assets/template.svg') { |f| Nokogiri::XML(f) }.at(:svg)
    unless @size.nil?
      xml.attributes['width'].value = "#{@size}px"
      xml.attributes['height'].value = "#{@size}px"
    end

    xml.css('rect').first.attributes['fill'].value = @background_color
    update_padding(xml, '100%') if @padding.presence

    xml
  end

  def canvg(svg_xml)
    html_template = File.open('assets/template.html').read
    svg_string = svg_xml.to_s
    html_template.gsub('SVG_STRING', svg_string)
  end

  def imagemagick
    svg_file = svg
    png_file = Tempfile.new([to_s, '.png'], 'tmp')

    MiniMagick::Tool::Convert.new do |convert|
      convert.background('none')
      convert.size("#{@size}x#{@size}")
      convert << svg_file.path
      convert << png_file.path
    end

    contents = png_file.read

    png_file.unlink
    svg_file.unlink

    contents
  end

  def update_padding(xml, default_size)
    size =
      if @size.presence
        @size.to_s.delete('px').to_i
      else
        default_size
      end

    message = 'Padding must be less than half of the size | ' \
              "size: #{@size}px, padding: #{@padding}px"
    raise message if size.is_a?(Integer) && @padding >= (size / 2)

    emoji_svg = xml.css('#emoji').first

    new_square_size = size.is_a?(Integer) ? size - (@padding * 2) : "#{size} - #{@padding * 2}"
    emoji_svg.attributes['height'].value = "#{new_square_size}px"
    emoji_svg.attributes['width'].value = "#{new_square_size}px"
    emoji_svg.attributes['x'].value = "#{@padding}px"
    emoji_svg.attributes['y'].value = "#{@padding}px"
  end
end
