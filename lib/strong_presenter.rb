require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/name_error'

require "strong_presenter/version"
require "strong_presenter/delegation"
require "strong_presenter/permissions"
require "strong_presenter/permissible"
require "strong_presenter/labelable"
require "strong_presenter/presenter"
require "strong_presenter/collection_presenter"
require "strong_presenter/railtie" if defined? Rails

module StrongPresenter
  class UninferrableSourceError < NameError
    def initialize(klass)
      super("Could not infer a source for #{klass}.")
    end
  end
end
