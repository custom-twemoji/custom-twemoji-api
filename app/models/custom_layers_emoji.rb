# frozen_string_literal: true

require 'unicode/emoji'

require_relative 'custom_emoji'
require_relative 'face'
require_relative 'twemoji/absolute_twemoji'
require_relative '../helpers/object'

# Defines a custom layers emoji
class CustomLayersEmoji < CustomEmoji
  attr_reader :xml

  def initialize(params)
    super

    @base_emoji_id = @params[:emoji_id]
    @remove_groups = @params[:remove_groups].to_s != 'false'
    @absolute_paths = @params[:absolute_paths].to_s != 'false'

    LOGGER.debug("Creating custom face with params: #{@params}")
    add_layers

    # Previously @xml was a Nokogiri XML parser
    @xml = @xml_template.to_xml
  end

  # Prints out the custom face as a unique string
  def to_s
    descriptors = {}
    descriptors[:base] = @base_emoji_id unless @base_emoji_id.nil?

    DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
      value = @params[feature_name]
      descriptors[feature_name] = value unless [nil, '', 'false', false].include?(value)
    end

    descriptors.map { |h| h.join('-') }.join('_-_')
  end

  private

  # Adds a feature of a Twemoji's XML to an XML template
  def add_all_feature_layers(layers)
    layers.each do |layer|
      emoji_svg = @xml_template.css('#emoji').first
      emoji_svg.add_child(layer)
    end
  end

  # Adds all layers to an XML template
  def add_layers
    @layers = layers

    @layers.each do |_, layer|
      add_all_feature_layers(layer)
    end
  end

  def get_layer_by_number(xml, path_number)
    children = xml.children

    message = "Layer number '#{path_number}' is not present on emoji"
    raise message if path_number > (children.length - 1)

    children[path_number]
  end

  def pluck_layers_from_twemoji(twemoji_xml, layers_value)
    xml_layers = []

    # Accept single integer, arrays, and strings like "2..13"
    case layers_value
    when String
      message = 'Layers as a string only supports x..y where x and y are integers | ' \
                "Didn't match supported pattern: '#{layers_value}'"
      raise message unless layers_value.match(/^\d+..\d+$/)

      layers_array = layers_value.split('..').map(&:to_i)
      layers_value = Range.new(layers_array[0], layers_array[1])

      if layers_value.first > layers_value.last
        layers_value = (layers_value.last..layers_value.first).to_a.reverse
      end
    when Integer
      layers_value = [layers_value]
    end

    layers_value.each do |number|
      xml_layers.push(get_layer_by_number(twemoji_xml, number))
    end

    xml_layers
  end

  def retrieve_and_cache_twemoji(twemojis, emoji_id, absolute_paths, remove_groups, emoji_cache_name)
    twemoji_xml =
      if absolute_paths
        AbsoluteTwemoji.new(@twemoji_version, emoji_id, remove_groups: remove_groups).xml
      else
        Twemoji.new(@twemoji_version, emoji_id, remove_groups).xml
      end

    twemojis[emoji_cache_name] = twemoji_xml
    [twemojis, twemoji_xml]
  end

  def get_xml_and_emoji_id(body_object, twemojis)
    emoji_input = body_object[:emoji].presence
    emoji_id = validate_emoji_input(emoji_input)

    remove_groups = body_object[:remove_groups].to_s == 'false' ? false : @remove_groups
    absolute_paths = body_object[:absolute_paths].to_s == 'false' ? false : @absolute_paths

    emoji_cache_name = "#{emoji_id}#{'-absolute' if absolute_paths}"

    layers_value = body_object[:layers]
    layer_identifier = "#{emoji_cache_name}#{layers_value}"

    twemoji_xml = twemojis[emoji_cache_name]
    if twemoji_xml.nil?
      # Save Twemojis to reduce number of fetches
      twemojis, twemoji_xml =
        retrieve_and_cache_twemoji(
          twemojis,
          emoji_id,
          absolute_paths,
          remove_groups,
          emoji_cache_name
        )
    end

    begin
      xml = pluck_layers_from_twemoji(twemoji_xml, layers_value)
    rescue StandardError => e
      raise "#{e.message} '#{emoji_input}'"
    end

    [xml, twemojis, layer_identifier]
  end

  def layers
    all_layers = {}
    twemojis = {}

    @params[:body].each do |body_object|
      xml, twemojis, layer_identifier = get_xml_and_emoji_id(body_object, twemojis)

      all_layers[layer_identifier] = xml
    end

    all_layers
  end
end
