begin
  require 'simplecov'
  SimpleCov.start do
    root '../../'
    command_name 'spec:integration:test:test'
    add_filter 'spec'
  end
rescue LoadError
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
