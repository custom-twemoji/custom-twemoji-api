# frozen_string_literal: true

require 'unicode/emoji'

require_relative 'custom_emoji'
require_relative 'face'
require_relative 'twemoji/twemoji'
require_relative '../helpers/object'

# Defines a custom face emoji
class CustomFace < CustomEmoji
  attr_reader :xml

  # Stacked from bottom to top
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

  def initialize(params)
    super

    @base_emoji_id = validate_emoji_input(@base_emoji_id, Face)
    raise "Emoji not a supported face: #{@params[:emoji_id]}" if @base_emoji_id.nil?

    base_layers = Face.find(@base_emoji_id)
    @raw = @params[:raw] == 'true' || false
    @base_twemoji = Twemoji.new(
      @twemoji_version,
      @base_emoji_id,
      base_layers,
      features_from_layers(base_layers),
      @raw
    ).xml

    if @raw
      @xml = @base_twemoji.to_xml
      return
    end

    validate_feature_params
    @features = features
    add_features

    # Previously @xml was a Nokogiri XML parser
    @xml = @xml_template.to_xml
  end

  # Prints out the custom face as a unique string
  def to_s
    @features.map { |h| h.join('-') }.join('_-_')
  end

  private

  # Adds a feature of a Twemoji's XML to an XML template
  def add_all_feature_layers(layers)
    layers.each do |layer|
      @xml_template.add_child(layer)
    end
  end

  # Adds all features to an XML template
  def add_features
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

  def features_from_layers(layers)
    layers.each_with_object({}) do |(key, value), out|
      value = value['name'] if value.is_a?(Hash)
      out[value.to_sym] ||= []
      out[value.to_sym] << key
    end
  end

  def validate_feature_params
    DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
      value = @params[feature_name]
      # Permit '' as a means of removing a feature
      next if value.blank?

      value = validate_emoji_input(value, Face)

      if Face.find(value).nil? || value == @base_emoji_id
        # Delete bad or duplicate parameter
        @params.delete(feature_name)
      else
        @params[feature_name] = value
      end
    end

    @params
  end

  def features
    all_features = {}
    twemojis = {}

    DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
      xml = nil
      emoji_id = nil
      if @params[feature_name].nil?
        xml = @base_twemoji
        emoji_id = @base_emoji_id
      else
        emoji_id = @params[feature_name].presence
        next if emoji_id.nil?

        # Save Twemojis to reduce number of fetches
        if twemojis[emoji_id].nil?
          layers = Face.find(emoji_id)
          features = features_from_layers(layers)
          xml = Twemoji.new(@twemoji_version, emoji_id, layers, features, false).xml

          twemojis[emoji_id] = xml
        else
          xml = twemojis[emoji_id]
        end
      end

      # Get nodes by feature (class)
      layers_for_feature = xml.css("[class='#{emoji_id}-#{feature_name}']") unless xml.nil?
      all_features[feature_name] = layers_for_feature unless layers_for_feature.empty?
    end

    all_features
  end
end
