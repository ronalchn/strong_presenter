require 'strong_presenter/view_context/build_strategy'
require 'request_store'

module StrongPresenter

  # Copied from Draper::ViewContext
  module ViewContext
    # Hooks into a controller or mailer to save the view context in {current}.
    def view_context
      super.tap do |context|
        StrongPresenter::ViewContext.current = context
      end
    end

    # Returns the current controller.
    def self.controller
      RequestStore.store[:current_controller]
    end

    # Sets the current controller.
    def self.controller=(controller)
      RequestStore.store[:current_controller] = controller
    end

    # Returns the current view context, or builds one if none is saved.
    #
    # @return [HelperProxy]
    def self.current
      RequestStore.store.fetch(:current_view_context) { build! }
    end

    # Sets the current view context.
    def self.current=(view_context)
      RequestStore.store[:current_view_context] = StrongPresenter::HelperProxy.new(view_context)
    end

    # Clears the saved controller and view context.
    def self.clear!
      RequestStore.store.delete :current_controller
      RequestStore.store.delete :current_view_context
    end

    # Builds a new view context for usage in tests. See {test_strategy} for
    # details of how the view context is built.
    def self.build
      build_strategy.call
    end

    # Builds a new view context and sets it as the current view context.
    #
    # @return [HelperProxy]
    def self.build!
      # send because we want to return the HelperProxy returned from #current=
      send :current=, build
    end

    # Configures the strategy used to build view contexts in tests, which
    # defaults to `:full` if `test_strategy` has not been called. Evaluates
    # the block, if given, in the context of the view context's class.
    #
    # @example Pass a block to add helper methods to the view context:
    #   StrongPresenter::ViewContext.test_strategy :fast do
    #     include ApplicationHelper
    #   end
    #
    # @param [:full, :fast] name
    #   the strategy to use:
    #
    #   `:full` - build a fully-working view context. Your Rails environment
    #   must be loaded, including your `ApplicationController`.
    #
    #   `:fast` - build a minimal view context in tests, with no dependencies
    #   on other components of your application.
    def self.test_strategy(name, &block)
      @build_strategy = StrongPresenter::ViewContext::BuildStrategy.new(name, &block)
    end

    # @private
    def self.build_strategy
      @build_strategy ||= StrongPresenter::ViewContext::BuildStrategy.new(:full)
    end

  end
end
