# frozen_string_literal: true

require 'yaml'

require_relative 'custom_emoji'
require_relative 'face'
require_relative 'twemoji'
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

    add_features

    # Previously @xml was a Nokogiri XML parser
    @xml = @xml_template.to_xml
  end

  # Adds a feature of a Twemoji's XML to an XML template
  def add_feature(feature_name, emoji_id_for_feature)
    emoji_id_for_feature = @emoji_id if emoji_id_for_feature.nil?

    twemoji_xml = Twemoji.new(@twemoji_version, emoji_id_for_feature).xml

    faces = Face.all(@twemoji_version)
    layers_to_add = faces.dig(emoji_id_for_feature, feature_name.to_s)
    add_all_feature_layers(layers_to_add, twemoji_xml)
  end

  def features
    @params.select { |key, _| DEFAULT_FEATURE_STACKING_ORDER.include?(key) }
  end

  # Adds all features to an XML template
  def add_features
    if @params[:order] == 'manual'
      features.each do |feature_name, emoji_id|
        add_feature(feature_name, emoji_id)
      end
    else
      DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
        emoji_id_for_feature = @params[feature_name]
        add_feature(feature_name, emoji_id_for_feature)
      end
    end
  end

  def to_s
    features.map { |h| h.join('-') }.join('_-_')
  end
end
