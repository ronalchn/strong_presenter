begin
  require 'simplecov'
  SimpleCov.start do
    root '../../'
    command_name 'spec:integration:test:spec'
    add_filter 'spec'
  end
rescue LoadError
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.expect_with(:rspec) {|c| c.syntax = :expect}
  config.order = :random
end
