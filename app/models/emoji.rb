# frozen_string_literal: true

require 'logger'
require 'mini_magick'
require 'net/http'
require 'nokogiri'
require 'tempfile'
require 'uri'
require 'yaml'

require_relative '../helper'

# Bottom to top layer
DEFAULT_FEATURE_STACKING_ORDER = [
  :head,
  :headwear,
  :cheeks,
  :mouth,
  :nose,
  :eyes,
  :eyewear,
  :other
]
DEFAULT_TWEMOJI_VERSION = '13.1.0'

class Emoji
  attr_reader :xml

  def initialize(params)
    @params = params
    template_file = File.open("assets/template.svg") { |f| Nokogiri::XML(f) }.at(:svg)
    @base_emoji_id = @params[:base_emoji_id]

    @time = @params[:time]
    @twemoji_version = @params[:twemoji_version].presence || DEFAULT_TWEMOJI_VERSION

    if @params[:order] == 'manual'
      features = get_feature_params

      features.each do |feature_name, emoji_id|
        add_feature(template_file, feature_name, emoji_id)
      end
    else
      DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
        emoji_id = @params[feature_name]
        add_feature(template_file, feature_name, emoji_id)
      end
    end

    @xml = template_file.to_xml
  end

  def to_s
    features = get_feature_params
    features.map {|h| h.join('-') }.join('_-_')
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

  def get_feature_params
    @params.select { |key, value| DEFAULT_FEATURE_STACKING_ORDER.include?(key) }
  end

  def get_emoji(name)
    github_url =
        'https://raw.githubusercontent.com/twitter/twemoji/'\
        "v#{@twemoji_version}/assets/svg/#{name}.svg"

    uri = URI.parse(github_url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      file = Nokogiri::XML(response.body)
      file.css("svg")[0]
    else
      raise
    end
  rescue SocketError, StandardError => e
    message = "Failed to access SVG from GitHub: #{github_url}"
    raise RuntimeError, message
  end

  # Adds a layer of an emoji file to a template file
  def add_layer(emoji_file, template_file, layer_number)
    # Duplicate or else it will be removed from the original file
    layer = emoji_file.children[layer_number].dup
    template_file.add_child(layer)
  end

  # Adds a feature of an emoji file to a template file
  def add_feature(template_file, feature_name, emoji_id)
    if emoji_id.nil?
      return if @base_emoji_id.nil?

      emoji_id = @base_emoji_id
    end

    emoji_file = get_emoji(emoji_id)
    yml_file = "app/models/twemoji/#{@twemoji_version}/faces.yml"
    faces = YAML.load(File.read(yml_file))

    layers_to_add = faces.dig(emoji_id, feature_name.to_s)

    invalid_data_message = "Invalid data in YML file: #{yml_file}"

    case layers_to_add
    when Integer
      # Feature corresponds to only one layer
      layer_number = layers_to_add

      add_layer(emoji_file, template_file, layer_number)
    when Array
      # Feature corresponds to more than one layer; add each individually
      layers_to_add.each do |layer_number|
        raise NameError, invalid_data_message if !layer_number.is_a?(Integer)

        add_layer(emoji_file, template_file, layer_number)
      end
    when nil
    else
      raise NameError, invalid_data_message
    end
  end
end
