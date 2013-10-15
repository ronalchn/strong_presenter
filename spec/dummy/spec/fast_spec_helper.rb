begin
  require 'simplecov'
  SimpleCov.start do
    root '../../'
    command_name 'spec:integration:test:fast_spec'
    add_filter 'spec'
  end
rescue LoadError
end

require 'strong_presenter'
require 'rspec'

