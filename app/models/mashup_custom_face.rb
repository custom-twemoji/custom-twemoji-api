# frozen_string_literal: true

require_relative 'face'
require_relative '../helpers/error'
require_relative '../helpers/hash'
require_relative '../helpers/random'

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

    amount = @params[:amount]&.to_i
    emojis = @params[:emojis]&.split(',') || []

    amount = FALLBACK_FACES_AMOUNT if emojis.empty? && amount.nil?

    message = "Emojis parameter on mashup should have two or more emojis: #{@params[:emojis]}"
    if amount.nil? && (emojis&.length.nil? || emojis.length < REQUIRED_FACES_AMOUNT)
      raise CustomTwemojiApiError.new(400), message
    end

    message = "Amount parameter on mashup should be greater than one: #{amount}"
    raise CustomTwemojiApiError.new(400), message if amount && amount < REQUIRED_FACES_AMOUNT

    message = "Amount parameter (#{amount}) exceeds number of supported faces (#{faces.length})"
    raise CustomTwemojiApiError.new(400), message if amount && amount > faces.length

    if amount
      difference = amount - emojis.length

      if difference.positive?
        difference.times do
          # Add emojis to bring up the count to match amount
          random_face = Face.random(@twemoji_version)
          face_emoji_id = random_face.keys[0]

          emojis.push(face_emoji_id)
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

      features = Face.find_with_features(@twemoji_version, emoji_id)

      features.each_key do |feature|
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
