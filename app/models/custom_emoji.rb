# frozen_string_literal: true

require 'mini_magick'
require 'nokogiri'
require 'securerandom'
require 'tempfile'

require_relative 'twemoji/twemoji'
require_relative '../helpers/object'
require_relative '../helpers/error'

# Defines an custom-built emoji
class CustomEmoji
  DEFAULT_PNG_SIZE = 128

  def initialize(params)
    @params = params

    @twemoji_version = Twemoji.validate_version(@params[:twemoji_version])

    @time = @params[:time]
    @size = @params[:size].presence
    @padding = (@params[:padding].presence || 0).to_s.delete('px').to_i
    @renderer = @params[:renderer]
    @background_color = @params[:background_color]

    @xml_template = xml_template
  end

  def update_node_attributes(node, emoji_id, feature, index, fill)
    feature_string = feature.presence ? "-#{feature}" : ''
    index_string = index.presence ? "-#{index}" : ''

    node[:id] = "#{emoji_id}#{feature_string}#{index_string}"
    node[:class] = "#{emoji_id} #{feature}"
    node[:fill] = fill unless fill.nil?

    node
  end

  def validate_emoji_input(emoji_input)
    return false if emoji_input == 'false'

    emoji_input = emoji_input.downcase

    if emoji_input[0..1] == 'u+'
      emoji_input = emoji_input[2..]
    elsif emoji_input.scan(Unicode::Emoji::REGEX).length == 1
      # Source: https://dev.to/ohbarye/convert-emoji-and-codepoints-each-other-in-ruby-27j
      emoji_input = emoji_input.each_codepoint.map { |n| n.to_s(16) }
      emoji_input = emoji_input.join('-') if emoji_input.is_a?(Array)
    elsif emoji_input.scan(Unicode::Emoji::REGEX).length > 1
      emoji_input = nil
    end

    message = "Emoji is not valid: #{emoji_input}"
    raise CustomTwemojiApiError.new(400), message if emoji_input.nil?

    emoji_input
  end

  def get_resource_in_file_format(resource)
    case @file_format
    when nil, 'svg'
      svg(resource)
    when 'png'
      png(resource)
    end
  end

  def svg
    target_directory = 'tmp'
    Dir.mkdir(target_directory) unless File.exist?(target_directory)
    svg = Tempfile.new([to_s, '.svg'], target_directory)

    File.write(svg.path, @xml)

    svg
  end

  def png(renderer, nonce)
    size = @size.presence || DEFAULT_PNG_SIZE
    renderer = @renderer.presence || renderer

    svg_xml = Nokogiri::XML(@xml)
    svg_xml.at(:svg).attributes['width'].value = "#{size}px"
    svg_xml.at(:svg).attributes['height'].value = "#{size}px"
    @xml = svg_xml

    update_padding(@xml, DEFAULT_PNG_SIZE) unless @padding.zero?

    case renderer.downcase
    when 'canvg'
      canvg(svg_xml, nonce)
    when 'imagemagick'
      imagemagick(size)
    else
      message = "Renderer not supported: #{@renderer} | Valid renderers: canvg, imagemagick"
      raise CustomTwemojiApiError.new(400), message
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
    update_padding(xml, '100%') unless @padding.zero?

    xml
  end

  def canvg(svg_xml, nonce)
    html_template = File.read('assets/template.html')
    svg_string = svg_xml.to_s

    html_template.gsub!('SVG_STRING', svg_string)
    html_template.gsub!('NONCE', nonce)
  end

  def imagemagick(size)
    svg_file = svg
    png_file = Tempfile.new([to_s, '.png'], 'tmp')

    MiniMagick::Tool::Convert.new do |convert|
      convert.background('none')
      convert.size("#{size}x#{size}")
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
    raise CustomTwemojiApiError.new(400), message if size.is_a?(Integer) && @padding >= (size / 2)

    emoji_svg = xml.css('#emoji').first

    new_square_size = size.is_a?(Integer) ? size - (@padding * 2) : "#{size} - #{@padding * 2}"
    emoji_svg.attributes['height'].value = "#{new_square_size}px"
    emoji_svg.attributes['width'].value = "#{new_square_size}px"
    emoji_svg.attributes['x'].value = "#{@padding}px"
    emoji_svg.attributes['y'].value = "#{@padding}px"
  end
end
