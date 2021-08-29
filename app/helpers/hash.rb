# frozen_string_literal: true

# Defines custom Hash methods
class Hash
  def symbolize_keys
    map do |(k, v)|
      [k.to_sym, v]
    end.to_h
  end
end
