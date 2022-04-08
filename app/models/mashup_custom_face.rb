# frozen_string_literal: true

require_relative 'face'
require_relative 'random'
require_relative '../helpers/hash'

# Defines a mashup custom face emoji
class MashupCustomFace < CustomFace
  attr_reader :xml

  # Mashups require this many faces to function
  REQUIRED_FACES_AMOUNT = 2

  # If no mashup-specific parameters are present, this is how many faces will be used
  FALLBACK_FACES_AMOUNT = 2

  def initialize(params)
    @params = params

    @twemoji_version = Twemoji.validate_version(@params[:twemoji_version])
    feature_counts = {}

    amount = @params[:amount].nil? ? nil : @params[:amount].to_i
    emojis = @params[:emojis]&.split(',') || []

    amount = FALLBACK_FACES_AMOUNT if emojis.empty? && amount.nil?

    message = "Emojis parameter on mashup should have two or more emojis: #{@params[:emojis]}"
    raise message if (emojis&.length.nil? || emojis.length < REQUIRED_FACES_AMOUNT) && amount.nil?

    message = "Amount parameter on mashup should be greater than one: #{amount}"
    raise message if amount && amount < REQUIRED_FACES_AMOUNT

    message = "Amount parameter (#{amount}) exceeds number of supported faces (#{faces.length})"
    raise message if amount && amount > faces.length

    if amount
      difference = amount - emojis.length

      if difference.positive?
        difference.times do
          # Add emojis to bring up the count to match amount
          emojis.push(faces.keys[rand(0..faces.length - 1)])
        end
      elsif difference.negative?
        difference.abs.times do
          # Remove emojis to bring down the count to match amount
          emojis.delete_at(rand(0..emojis.length - 1))
        end
      end
    end

    emojis.each do |emoji|
      emoji_id = validate_emoji_input(emoji)
      raise "Emoji is not a supported face: #{emoji}" if emoji_id.nil?

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
          (@params[:use_every_feature] || feature_name == :head) ? 1 : 0.5
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
