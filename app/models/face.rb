# frozen_string_literal: true

require 'yaml'

require_relative 'twemoji/twemoji'

# Defines an emoji face
class Face
  # Retrieves all faces
  def self.all(twemoji_version)
    twemoji_version = Twemoji.validate_version(twemoji_version)
    raise 'Twemoji version is incorrectly nil' if twemoji_version.nil?

    yml_file = YAML.safe_load(File.read('app/models/twemoji/face.yml'))

    version_hash = {}
    version_found = false

    yml_file.each do |key, value|
      version_found ||= key == twemoji_version
      next if !version_found || value.nil?

      version_hash = value.merge!(version_hash)
    end

    version_hash
  end

  def self.find_with_layers(twemoji_version, id)
    face = all(twemoji_version)[id]

    message =
      "Emoji (#{id}) was not found to be a supported face for Twemoji version #{twemoji_version}"
    raise message if face.nil?

    face
  end

  def self.find_with_features(twemoji_version, id)
    layers = find_with_layers(twemoji_version, id)

    return if layers.nil?

    layers.each_with_object({}) do |(key, value), out|
      value = value['name'] if value.is_a?(Hash)
      out[value.to_sym] ||= []
      out[value.to_sym] << key
    end
  end
end
