# frozen_string_literal: true

require_relative 'error'
require_relative 'hash'

# Defines helper functions for randomizing
class Random
  def self.from_hash(hash)
    hash.keys[
      rand(0..hash.length - 1)
    ]
  end

  def self.check_float(string, param_name)
    float = Float(string, exception: false)

    if !float.nil? && (float > 1 || float.negative?)
      message = "Value for the parameter #{param_name} is not between 0 and 1: #{string}"
      raise CustomTwemojiApiError.new(400), message
    end

    float
  end
end
