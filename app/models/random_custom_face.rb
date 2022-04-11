# frozen_string_literal: true

require_relative 'face'
require_relative '../helpers/hash'
require_relative '../helpers/random'

# Defines a random custom face emoji
class RandomCustomFace < CustomFace
  attr_reader :xml

  def initialize(params)
    @params = params

    @twemoji_version = params[:twemoji_version]

    DEFAULT_FEATURE_STACKING_ORDER.each do |feature_name|
      process_feature_param(@params[feature_name], feature_name)
    end

    @params[:emoji_id] = nil
    @params = @params.symbolize_keys

    super
  end

  private

  def valid_float?(string)
    # The double negation turns this into an actual boolean true - if you're
    # okay with "truthy" values (like 0.0), you can remove it.

    !!Float(string)
  rescue StandardError
    false
  end

  def add_random_twemoji(feature_name)
    @params[feature_name] = nil

    while @params[feature_name].nil?
      random_face = Face.random(@twemoji_version)
      face_emoji_id = random_face.keys[0]

      features = Face.find_with_features(@twemoji_version, face_emoji_id)
      feature = features[feature_name]
      @params[feature_name] = face_emoji_id unless feature.nil?
    end
  end

  def process_feature_param(param, feature_name)
    case param
    when 'true'
      add_random_twemoji(feature_name)
    when 'false'
      nil
    else
      input_param = Random.check_float(param, feature_name)
      chance = input_param.presence || feature_name == :head ? 1 : 0.5
      add_random_twemoji(feature_name) if rand < chance
    end
  end
end
