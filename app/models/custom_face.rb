# frozen_string_literal: true

require 'unicode/emoji'

require_relative 'custom_emoji'
require_relative 'face'
require_relative 'twemoji/absolute_twemoji'
require_relative '../helpers/object'

# Defines a custom face emoji
class CustomFace < CustomEmoji
  attr_reader :xml

  # Stacked from bottom to top
  DEFAULT_FEATURE_STACKING_ORDER = %i[
    head
    cheeks
    mouth
    nose
    eyes
    eyewear
    headwear
    other
  ].freeze

  def initialize(params)
    super

    unless @base_emoji_id.nil?
      @raw = @params[:raw] == 'true' || false
      prepare_base_emoji
      if @raw
        @xml = @base_twemoji.to_xml
        return
      end
    end
    LOGGER.debug("Creating custom face with params: #{@params}")

    add_features

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

  def prepare_base_emoji
    @base_emoji_id = validate_emoji_input(@base_emoji_id, Face)
    raise "Base emoji is not a supported face: #{@params[:emoji_id]}" if @base_emoji_id.nil?

    base_layers = Face.find(@base_emoji_id, @twemoji_version)
    @base_twemoji = AbsoluteTwemoji.new(
      @twemoji_version,
      @base_emoji_id,
      base_layers,
      Face.features_from_layers(base_layers),
      @raw
    ).xml
  end

  # Adds a feature of a Twemoji's XML to an XML template
  def add_all_feature_layers(layers)
    layers.each do |layer|
      emoji_svg = @xml_template.css('#emoji').first
      emoji_svg.add_child(layer)
    end
  end

  # Adds all features to an XML template
  def add_features
    @features = features

    if @params[:order] == 'manual'
      features.each do |_, feature_xml|
        add_all_feature_layers(feature_xml)
      end
    else
      @features.each do |_, feature_xml|
        add_all_feature_layers(feature_xml)
      end
    end
  end

  def validate_feature_param(feature_name)
    value = @params[feature_name]
    # Permit '' as a means of removing a feature
    return if value.blank?

    value = validate_emoji_input(value, Face)

    # Permit false as a means of removing a feature
    if (Face.find(value, @twemoji_version).nil? || value == @base_emoji_id) && value != false
      # Delete bad or duplicate parameter
      @params.delete(feature_name)
    else
      @params[feature_name] = value
    end
  end

  def validate_feature_params
    DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
      validate_feature_param(feature_name)
    end

    @params
  end

  def cache_twemoji(twemojis, emoji_id)
    layers = Face.find(emoji_id, @twemoji_version)
    features = Face.features_from_layers(layers)
    xml = AbsoluteTwemoji.new(@twemoji_version, emoji_id, layers, features, false).xml

    twemojis[emoji_id] = xml
    twemojis
  end

  def get_xml_and_emoji_id(feature_name, twemojis)
    xml, emoji_id = nil

    if @params[feature_name].nil?
      return [nil, nil, twemojis] if @base_emoji_id.nil?

      xml = @base_twemoji
      emoji_id = @base_emoji_id
    else
      emoji_id = @params[feature_name].presence
      return [nil, nil, twemojis] if emoji_id.nil?

      if twemojis[emoji_id].nil?
        # Save Twemojis to reduce number of fetches
        twemojis = cache_twemoji(twemojis, emoji_id)
      end

      xml = twemojis[emoji_id]
    end

    [emoji_id, xml, twemojis]
  end

  def features
    validate_feature_params
    all_features = {}
    twemojis = {}

    DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
      emoji_id, xml, twemojis = get_xml_and_emoji_id(feature_name, twemojis)
      next if emoji_id.nil?

      # Get nodes by feature (class)
      layers_for_feature = xml.css("[class='#{emoji_id}-#{feature_name}']") unless xml.nil?
      all_features[feature_name] = layers_for_feature unless layers_for_feature.empty?
    end

    all_features
  end
end
