# frozen_string_literal: true

# Defines the custom error class to contain a status code
class CustomTwemojiApiError < StandardError
  attr_reader :status_code

  def initialize(status_code)
    super
    @status_code = status_code
  end
end
