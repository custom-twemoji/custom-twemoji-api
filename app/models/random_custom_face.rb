# frozen_string_literal: true

require_relative 'face'
require_relative '../helpers/hash'

# Defines a random custom face emoji
class RandomCustomFace < CustomFace
  attr_reader :xml

  def initialize(params)
    @params = params
    @faces = Face.all(@params[:twemoji_version])

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
      face = @faces.keys[rand(0..@faces.length - 1)]
      features = features_from_layers(@faces[face])
      feature = features[feature_name]
      @params[feature_name] = face unless feature.nil?
    end
  end

  def check_float(string)
    float = Float(string, exception: false)
    if !float.nil? && (float > 1 || float.negative?)
      raise "Value for the parameter #{feature_name} is not between 0 and 1: #{param}"
    end

    float
  end

  def process_feature_param(param, feature_name)
    case param
    when 'true'
      add_random_twemoji(feature_name)
    when 'false'
      nil
    else
      float = check_float(param)
      chance = float.presence || 0.5
      add_random_twemoji(feature_name) if rand < chance || feature_name == :head
    end
  end
end
