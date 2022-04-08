# frozen_string_literal: true

require 'unicode/emoji'

require_relative 'custom_emoji'
require_relative 'face'
require_relative 'twemoji/absolute_twemoji'
require_relative '../helpers/object'

# Defines a custom face emoji
class CustomFace < CustomEmoji
  attr_reader :xml, :url

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

    @base_emoji_id = @params[:emoji_id]
    @remove_groups = @params[:remove_groups]

    prepare_base_emoji unless @base_emoji_id.nil?
    LOGGER.debug("Creating custom face with params: #{@params}")

    @url = define_url

    add_features

    # Previously @xml was a Nokogiri XML parser
    # Note: Newlines are not removable via Nokigiri: https://github.com/sparklemotion/nokogiri/issues/233
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

  def faces
    @faces ||= Face.all(@params[:twemoji_version])
  end

  def define_url
    url_string = ''

    DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
      emoji = @params[feature_name] || ''
      feature_hash = { feature_name => emoji }

      url_string =
        if url_string.blank?
          "#{emoji}?"
        else
          "#{url_string}#{'&' unless url_string.end_with?('?')}#{URI.encode_www_form(feature_hash)}"
        end
    end

    url_string
  end

  def prepare_base_emoji
    @base_emoji_id = validate_emoji_input(@base_emoji_id)
    raise "Base emoji is not a supported face: #{@params[:emoji_id]}" if @base_emoji_id.nil?

    @features = Face.find_with_features(@twemoji_version, @base_emoji_id)
    @base_twemoji = AbsoluteTwemoji.new(@twemoji_version, @base_emoji_id).xml

    base_layers = Face.find_with_layers(@twemoji_version, @base_emoji_id)
    @base_twemoji = label_layers_by_feature(@base_twemoji, base_layers, @base_emoji_id)

    @base_twemoji
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

    value = validate_emoji_input(value)

    # Permit false as a means of removing a feature
    if (Face.find_with_layers(@twemoji_version, value).nil? || value == @base_emoji_id) && value != false
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
    layers = Face.find_with_layers(@twemoji_version, emoji_id)

    xml = AbsoluteTwemoji.new(@twemoji_version, emoji_id).xml
    xml = label_layers_by_feature(xml, layers, emoji_id)

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
      layers_for_feature = xml.css("[class='#{emoji_id} #{feature_name}']") unless xml.nil?
      all_features[feature_name] = layers_for_feature unless layers_for_feature.empty?
    end

    all_features
  end

  def subtract_layers(shape, hole)
    shape.attributes['d'].value = "#{shape.attributes['d'].value} #{hole.attributes['d'].value}"
    hole[:class] = 'hole'
    nil
  end

  def find_layer_underneath(layers, current_index, xml)
    (current_index - 1).downto(0) do |i|
      return xml.children[i] unless ['', 'subtract'].include?(layers[i])
    end

    raise "No bottom layer to subtract with layer #{current_index}"
  end

  def determine_layer_format(layers, index, xml)
    case layers[index]
    when 'subtract'
      subtract_layers(find_layer_underneath(layers, index, xml), xml.children[index])
    when String
      [
        layers[index].to_sym,
        nil
      ]
    when Hash
      [
        layers[index]['name'].to_sym,
        layers[index]['fill']
      ]
    end
  end

  def label_layers_of_feature(xml, layers, id, node, index)
    if layers[index].nil?
      message = "Found missing layer data | emoji: #{id} , layer: #{index} , xml: #{node}"
      raise NameError, message
    else
      feature, fill = determine_layer_format(layers, index, xml)

      update_node_attributes(node, id, feature, index, fill) unless feature.nil?
    end
  end

  def label_layers_by_feature(xml, layers, id)
    xml.children.each_with_index do |child, index|
      label_layers_of_feature(xml, layers, id, child, index)
    end

    if xml.children.length < layers.length
      raise "For emoji #{id}, the number of layers in the model (#{layers.length}) is greater than"\
            " the number in the SVG (#{xml.children.length})"
    end

    xml.css("[class='hole']").each(&:remove)
    xml
  end
end
