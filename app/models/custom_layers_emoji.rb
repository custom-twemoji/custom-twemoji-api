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

    # unless @base_emoji_id.nil?
    #   @raw = @params[:raw] == 'true' || false
    #   prepare_base_emoji
    #   if @raw
    #     @xml = @base_twemoji.to_xml
    #     return
    #   end
    # end

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

  # def prepare_base_emoji
  #   @base_emoji_id = validate_emoji_input(@base_emoji_id, Face, 'find')
  #   raise "Base emoji is not a supported face: #{@params[:emoji_id]}" if @base_emoji_id.nil?

  #   base_layers = Face.find(@base_emoji_id, @twemoji_version)
  #   @base_twemoji = AbsoluteTwemoji.new(
  #     @twemoji_version,
  #     @base_emoji_id,
  #     base_layers,
  #     Face.features_from_layers(base_layers),
  #     @raw
  #   ).xml
  # end

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

    # if @params[:order] == 'manual'
    #   features.each do |_, feature_xml|
    #     add_all_feature_layers(feature_xml)
    #   end
    # else
    #   @features.each do |_, feature_xml|
    #     add_all_feature_layers(feature_xml)
    #   end
    # end

    @layers.each do |_, layer|
      add_all_feature_layers(layer)
      # emoji_svg = @xml_template.css('#emoji').first
      # emoji_svg.add_child(layer)
    end
  end

  # def validate_feature_param(feature_name)
  #   value = @params[feature_name]
  #   # Permit '' as a means of removing a feature
  #   return if value.blank?

  #   value = validate_emoji_input(value, Face, 'find')

  #   # Permit false as a means of removing a feature
  #   if (Face.find(@twemoji_version, value).nil? || value == @base_emoji_id) && value != false
  #     # Delete bad or duplicate parameter
  #     @params.delete(feature_name)
  #   else
  #     @params[feature_name] = value
  #   end
  # end

  # def validate_feature_params
  #   DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
  #     validate_feature_param(feature_name)
  #   end

  #   @params
  # end

  def get_layer_by_number(xml, path_number)
    children = xml.children

    message = "Layer number '#{path_number}' is not present on emoji"
    raise message if path_number > (children.length - 1)

    children[path_number]
  end

  def pluck_layers_from_twemoji(twemoji_xml, layers_value)
    xml_layers = []

    # Accept single integer, arrays, and strings like "1..3"
    if layers_value.is_a?(String)
      message = "Layers as a string only supports x..y where x and y are integers | " \
        "Didn't match supported pattern: '#{layers_value}'"
      raise message unless layers_value.match(/^\d+..\d+$/)

      layers_value = eval(layers_value)
      if layers_value.first > layers_value.last
        layers_value = (layers_value.last..layers_value.first).to_a.reverse
      end
    elsif layers_value.is_a?(Integer)
      layers_value = [layers_value]
    end

    layers_value.each do |number|
      xml_layers.push(get_layer_by_number(twemoji_xml, number))
    end

    xml_layers
  end

  def retrieve_and_cache_twemoji(twemojis, emoji_id, raw, emoji_cache_name)
    # layers = Face.find(@twemoji_version, emoji_id)
    # features = Face.features_from_layers(layers)

    twemoji_xml =
      if raw
        Twemoji.new(@twemoji_version, emoji_id).xml
      else
        AbsoluteTwemoji.new(@twemoji_version, emoji_id).xml
      end

    twemojis[emoji_cache_name] = twemoji_xml
    [twemojis, twemoji_xml]
  end

  def get_xml_and_emoji_id(body_object, twemojis)
    # xml, emoji_id = nil

    # if @params[object].nil?
    #   return [nil, nil, twemojis] if @base_emoji_id.nil?

    #   xml = @base_twemoji
    #   emoji_id = @base_emoji_id
    # else
      emoji_input = body_object[:emoji].presence

      emoji_id = validate_emoji_input(emoji_input, Twemoji, 'new')
      raw = body_object[:raw] || false
      emoji_cache_name = "#{emoji_id}#{'-raw' if raw}"

      layers_value = body_object[:layers]
      layer_identifier = "#{emoji_cache_name}#{layers_value}"

      # return [nil, nil, twemojis] if emoji_id.nil?

      twemoji_xml = twemojis[emoji_cache_name]
      if twemoji_xml.nil?
        # Save Twemojis to reduce number of fetches
        twemojis, twemoji_xml =
          retrieve_and_cache_twemoji(twemojis, emoji_id, raw, emoji_cache_name)
      end

      begin
        xml = pluck_layers_from_twemoji(twemoji_xml, layers_value)
      rescue => error
        raise "#{error.message} '#{emoji_input}'"
      end
    # end

    [emoji_id, xml, twemojis, layer_identifier]
  end

  def layers
    # validate_feature_params
    all_layers = {}
    twemojis = {}

    @params[:body].each_with_index do |body_object, i|
      emoji_id, xml, twemojis, layer_identifier = get_xml_and_emoji_id(body_object, twemojis)

      # Get nodes by feature (class)
      # layers_for_object = xml.css("[class='#{emoji_id}-#{i}']") unless xml.nil?
      # all_layers[object] = layers_for_object unless layers_for_object.empty?

      all_layers[layer_identifier] = xml
    end

    all_layers
  end
end
