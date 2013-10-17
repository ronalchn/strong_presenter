begin
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
rescue LoadError
end

require 'bundler/setup'
require 'strong_presenter'
require 'rails/version'
require 'action_controller'
require 'action_controller/test_case'
require 'support/models'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.expect_with(:rspec) {|c| c.syntax = :expect}
  config.order = :random
end

class Model; end

class Product < Model; end
class ProductPresenter < StrongPresenter::Presenter; end
class ProductsPresenter < StrongPresenter::CollectionPresenter; end

class OtherPresenter < StrongPresenter::Presenter; end

module Namespaced
  class Product < Model; end
  class ProductPresenter < StrongPresenter::Presenter; end

  class OtherPresenter < StrongPresenter::Presenter; end
end

class WheelPresenter < StrongPresenter::Presenter; end
class CarPresenter < StrongPresenter::Presenter; end

# After each example, revert changes made to the class
def protect_class(klass)
  before { stub_const klass.name, Class.new(klass) }
end

def protect_module(mod)
  before { stub_const mod.name, mod.dup }
end
