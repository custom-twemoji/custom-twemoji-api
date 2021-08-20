# frozen_string_literal: true

require 'yaml'

require_relative 'twemoji'

# Defines an emoji face
class Face
  # Retrieves all faces
  def self.all(twemoji_version)
    twemoji_version = Twemoji::DEFAULT_VERSION if twemoji_version.nil?
    yml_file = "app/models/twemoji/#{twemoji_version}/face.yml"
    YAML.safe_load(File.read(yml_file))
  end
end
