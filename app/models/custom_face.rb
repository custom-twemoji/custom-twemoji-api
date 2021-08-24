# frozen_string_literal: true

require 'yaml'

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

    base_layers = Face.find(@emoji_id)
    @raw = @params[:raw] == 'true' || false
    @base_twemoji = Twemoji.new(
      @twemoji_version,
      @emoji_id,
      base_layers,
      features_from_layers(base_layers),
      @raw
    ).xml

    if @raw
      @xml = @base_twemoji.to_xml
      return
    end

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
      features.each do |_, emoji_id|
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

  def features
    all_features = {}
    twemojis = {}

    DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
      xml = nil
      if @params[feature_name.to_sym].nil?
        xml = @base_twemoji
      else
        emoji_id = @params[feature_name].presence
        next if emoji_id.nil?

        # Save Twemojis to reduce number of fetches
        if twemojis[emoji_id].nil?
          layers = Face.find(emoji_id)
          features = features_from_layers(layers)
          xml = Twemoji.new(@twemoji_version, emoji_id, layers, features, false).xml

          twemojis[@emoji_id] = xml
        else
          xml = twemojis[@emoji_id]
        end
      end

      # Get nodes by feature (class)
      layers_for_feature = xml.css("[class=#{feature_name}]") unless xml.nil?
      all_features[feature_name] = layers_for_feature if layers_for_feature.length > 0
    end

    all_features
  end
end