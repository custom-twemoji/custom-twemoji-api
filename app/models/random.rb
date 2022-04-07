# frozen_string_literal: true

require_relative 'face'
require_relative '../helpers/hash'

class Random
  def self.check_float(string, param_name)
    float = Float(string, exception: false)

    if !float.nil? && (float > 1 || float.negative?)
      raise "Value for the parameter #{param_name} is not between 0 and 1: #{string}"
    end

    float
  end
end
