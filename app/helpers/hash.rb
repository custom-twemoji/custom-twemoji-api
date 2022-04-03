# frozen_string_literal: true

# Defines custom Hash methods
class Hash
  def symbolize_keys
    to_h do |(k, v)|
      [k.to_sym, v]
    end
  end
end
