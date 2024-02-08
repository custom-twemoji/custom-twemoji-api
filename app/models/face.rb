# frozen_string_literal: true

require 'yaml'

require_relative 'twemoji/twemoji'
require_relative '../helpers/error'
require_relative '../helpers/random'

# Defines an emoji face
class Face
  # Retrieves all faces
  def self.all(twemoji_version)
    yml_file = YAML.safe_load_file('app/models/twemoji/face.yml')

    version_hash = {}
    version_found = false

    yml_file.each do |key, value|
      version_found ||= key == twemoji_version
      next if !version_found || value.nil?

      version_hash = value.merge!(version_hash)
    end

    version_hash
  end

  def self.layers_to_features(layers)
    return if layers.nil?

    layers.each_with_object({}) do |(key, value), out|
      value = value['name'] if value.is_a?(Hash)
      out[value.to_sym] ||= []
      out[value.to_sym] << key
    end
  end

  def self.find_with_layers(twemoji_version, id)
    face = all(twemoji_version)[id]

    message =
      "Emoji (#{id}) was not found to be a supported face for Twemoji version #{twemoji_version}"
    raise CustomTwemojiApiError.new(400), message if face.nil?

    face
  end

  def self.find_with_glyph(twemoji_version, id)
    find_with_layers(twemoji_version, id)['glyph']
  end

  def self.find_with_features(twemoji_version, id)
    layers = find_with_layers(twemoji_version, id)['layers']
    layers_to_features(layers)
  end

  def self.random(twemoji_version)
    faces = all(twemoji_version)
    random_face = Random.from_hash(faces)

    { random_face.to_s => faces[random_face] }
  end
end
