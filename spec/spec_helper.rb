# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_group 'Models', 'app/models'
end

require 'logger'
require 'rspec'
require 'webmock/rspec'

$LOAD_PATH.unshift(File.expand_path('../..', __dir__))

LOGGER = Logger.new($stdout)
LOGGER.level = Logger::WARN

require 'nokogiri'
require 'yaml'

Dir[File.expand_path('../app/models/**/*.rb', __dir__)].each do |file|
  require_relative "../#{file.sub(%r{^.+/app/models/}, 'app/models/')}"
end

RSpec.configure do |config|
  config.order = :defined
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
