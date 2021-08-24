# frozen_string_literal: true

require 'yaml'

require_relative 'twemoji/twemoji'

# Defines an emoji face
class Face
  # Retrieves all faces
  def self.all(twemoji_version = Twemoji.latest)
    yml_file = "app/models/twemoji/#{twemoji_version}/face.yml"
    YAML.safe_load(File.read(yml_file))
  end

  def self.find(id)
    all[id]
  end
end
