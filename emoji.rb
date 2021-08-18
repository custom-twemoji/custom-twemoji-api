# frozen_string_literal: true

require 'mini_magick'
require 'nokogiri'
require 'tempfile'

# Bottom to top layer
DEFAULT_STACKING_ORDER = [
  :head,
  :cheeks,
  :mouth,
  :nose,
  :eyes,
  :eyewear,
  :other
]

class Emoji
  attr_reader :xml

  def initialize(params)
    @params = params
    base_file = get_asset('base').at(:svg)

    if @params[:order] == 'manual'
      parts = get_part_params

      parts.each do |key, value|
        next if value.nil?
        base_file.add_child(get_part_from_file(key, value).to_s)
      end
    else
      DEFAULT_STACKING_ORDER.each do |key|
        value = @params[key]
        next if value.nil?
        base_file.add_child(get_part_from_file(key, value).to_s)
      end
    end

    @xml = base_file.to_xml
    @time = @params[:time]
  end

  def to_s
    parts = get_part_params
    parts.map {|h| h.join('-') }.join('_-_')
  end

  def svg
    filepath = [to_s, '.xvg']
    svg = Tempfile.new(filepath, 'tmp')

    File.open(svg.path, "w") do |f|
      f.write(@xml)
    end

    svg
  end

  def png
    filepath = [to_s, '.png']
    png = Tempfile.new(filepath, 'tmp')

    svg_file = svg

    MiniMagick::Tool::Convert.new do |convert|
      convert.background('none')
      convert << svg_file.path
      convert << png.path
    end

    contents = png.read
    png.unlink
    svg_file.unlink

    contents
  end

  private

  def get_part_params
    @params.select { |key, value| DEFAULT_STACKING_ORDER.include?(key) }
  end

  def get_asset(name)
    File.open("assets/#{name}.svg") { |f| Nokogiri::XML(f) }
  end

  def get_part_from_file(part, file_name)
    file = get_asset(file_name)
    file.at_css("[id='#{part}']")
  end
end
