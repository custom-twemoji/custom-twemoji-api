# frozen_string_literal: true

require_relative 'face'
require_relative 'random'
require_relative '../helpers/hash'

# Defines a mashup custom face emoji
class MashupCustomFace < CustomFace
  attr_reader :xml

  def initialize(params)
    @params = params

    @twemoji_version = Twemoji.validate_version(@params[:twemoji_version])
    feature_counts = {}

    emojis = @params[:emojis]&.split(',')

    message = "Emojis parameter should have two or more emojis on /v1/faces/mashup: #{@params[:emojis]}"
    raise message if emojis&.length.nil? || emojis.length < 2

    emojis.each do |emoji|
      emoji_id = validate_emoji_input(emoji)
      raise "Emoji is not a supported face: #{emoji}" if emoji_id.nil?

      puts emoji_id

      features = Face.find_with_features(@twemoji_version, emoji_id)

      features.each do |feature, _|
        key = feature_counts[feature] || []
        feature_counts[feature] = key.push(emoji_id)
      end
    end

    feature_counts.each do |feature_name, feature_count|
      input_param = Random.check_float(@params[feature_name], feature_name)

      chance =
        if input_param.nil?
          # rubocop:disable Style/TernaryParentheses
          (@params[:every_feature] || feature_name == :head) ? 1 : 0.5
          # rubocop:enable Style/TernaryParentheses
        else
          input_param
        end

      include_feature = true if rand < chance

      @params[feature_name] = feature_count[rand(0..feature_count.length - 1)] if include_feature
    end

    super
  end
end
