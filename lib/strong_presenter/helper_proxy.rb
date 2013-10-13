module StrongPresenter
  # Provides access to helper methods - both Rails built-in helpers, and those
  # defined in your application.

  # Copied from Draper::HelperProxy
  class HelperProxy

    # @overload initialize(view_context)
    def initialize(view_context)
      @view_context = view_context
    end

    # Sends helper methods to the view context.
    def method_missing(method, *args, &block)
      self.class.define_proxy method
      send(method, *args, &block)
    end

    delegate :capture, to: :view_context

    protected

    attr_reader :view_context

    private

    def self.define_proxy(name)
      define_method name do |*args, &block|
        view_context.send(name, *args, &block)
      end
    end

  end
end
