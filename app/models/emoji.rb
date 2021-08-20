# frozen_string_literal: true

require 'mini_magick'
require 'net/http'
require 'nokogiri'
require 'tempfile'
require 'uri'
require 'yaml'

require_relative '../helpers/object'

# Bottom to top layer
DEFAULT_FEATURE_STACKING_ORDER = %i[
  head
  headwear
  cheeks
  mouth
  nose
  eyes
  eyewear
  other
].freeze
DEFAULT_TWEMOJI_VERSION = '13.1.0'

# Defines an emoji
class Emoji
  attr_reader :xml

  def initialize(params)
    @params = params
    @time = @params[:time]
    @base_emoji_id = @params[:base_emoji_id]
    @twemoji_version = @params[:twemoji_version].presence || DEFAULT_TWEMOJI_VERSION
    @template_file = File.open('assets/template.svg') { |f| Nokogiri::XML(f) }.at(:svg)

    add_features
    @xml = @template_file.to_xml
  end

  def to_s
    features.map { |h| h.join('-') }.join('_-_')
  end

  def svg
    svg = Tempfile.new([to_s, '.xvg'], 'tmp')

    File.open(svg.path, 'w') do |f|
      f.write(@xml)
    end

    svg
  end

  def png
    png = Tempfile.new([to_s, '.png'], 'tmp')
    svg_file = svg

    convert_svg_to_png(svg_filepath, png_filepath)

    contents = png.read
    png.unlink
    svg_file.unlink

    contents
  end

  private

  def build_github_url(emoji_id)
    'https://raw.githubusercontent.com/twitter/twemoji/'\
    "v#{@twemoji_version}/assets/svg/#{emoji_id}.svg"
  end

  def get_original_emoji(id)
    github_url = build_github_url(id)
    response = Net::HTTP.get_response(URI.parse(github_url))

    case response
    when Net::HTTPSuccess
      Nokogiri::XML(response.body).css('svg')[0]
    else raise
    end
  rescue StandardError => e
    raise "Failed to access SVG from GitHub: #{github_url} | Error: #{e.message}"
  end

  # Adds a layer of an emoji file to a template file
  def add_layer(emoji_file, layer_number)
    # Duplicate or else it will be removed from the original file
    layer = emoji_file.children[layer_number].dup
    @template_file.add_child(layer)
  end

  def add_multiple_layers(emoji_file, layers)
    layers.each do |layer|
      raise NameError, "Invalid data in YML file: #{yml_file}" unless layer.is_a?(Integer)

      add_layer(emoji_file, layer)
    end
  end

  # Adds all layers for a feature
  def add_all_feature_layers(layers, emoji_file)
    case layers
    when Integer
      # Feature is an integer corresponding to only one layer
      add_layer(emoji_file, layers)
    when Array
      # Feature is an array corresponding to more than one layer
      add_multiple_layers(emoji_file, layers)
    when nil
    else raise NameError, "Invalid data in YML file: #{yml_file}"
    end
  end

  # Adds a feature of an emoji file to a template file
  def add_feature(feature_name, emoji_id)
    if emoji_id.nil?
      return if @base_emoji_id.nil?

      emoji_id = @base_emoji_id
    end

    emoji_file = get_original_emoji(emoji_id)
    yml_file = "app/models/twemoji/#{@twemoji_version}/faces.yml"
    faces = YAML.safe_load(File.read(yml_file))

    layers_to_add = faces.dig(emoji_id, feature_name.to_s)
    add_all_feature_layers(layers_to_add, emoji_file)
  end

  def convert_svg_to_png(svg_filepath, png_filepath)
    MiniMagick::Tool::Convert.new do |convert|
      convert.background('none')
      convert << svg_filepath
      convert << png_filepath
    end
  end

  def features
    @params.select { |key, _| DEFAULT_FEATURE_STACKING_ORDER.include?(key) }
  end

  # Adds all features of an emoji file to a template
  def add_features
    if @params[:order] == 'manual'
      features.each do |feature_name, emoji_id|
        add_feature(feature_name, emoji_id)
      end
    else
      DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
        emoji_id = @params[feature_name]
        add_feature(feature_name, emoji_id)
      end
    end
  end
end
