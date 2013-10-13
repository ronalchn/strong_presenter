require 'action_view'
require 'active_model/naming'
require 'active_model/serialization'
require 'active_model/serializers/json'
require 'active_model/serializers/xml'
require 'active_support/concern'
require 'active_support/inflector'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/name_error'

require "strong_presenter/version"
require "strong_presenter/view_helpers"
require "strong_presenter/helper_proxy"
require "strong_presenter/view_context"
require "strong_presenter/delegation"
require "strong_presenter/permissions"
require "strong_presenter/permissible"
require "strong_presenter/presenter"
require "strong_presenter/collection_presenter"
require "strong_presenter/factory"
require "strong_presenter/controller_additions"
require "strong_presenter/railtie" if defined? Rails

module StrongPresenter
  def self.setup_action_controller(base)
    base.class_eval do
      include StrongPresenter::ViewContext
      include StrongPresenter::ControllerAdditions

      before_filter do |controller|
        StrongPresenter::ViewContext.clear!
        StrongPresenter::ViewContext.controller = controller
      end
    end
  end

  def self.setup_action_mailer(base)
    base.class_eval do
      include StrongPresenter::ViewContext
    end
  end

  # Note: we do not want to patch ActiveRecord

  class UninferrablePresenterError < NameError
    def initialize(klass)
      super("Could not infer a presenter for #{klass}.")
    end
  end

  class UninferrableSourceError < NameError
    def initialize(klass)
      super("Could not infer a source for #{klass}.")
    end
  end
end
