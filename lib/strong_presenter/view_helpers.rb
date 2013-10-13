module StrongPresenter
  # Provides the {#helpers} method used in {Presenter} and {CollectionPresenter}
  # to call the Rails helpers.

  # Copy of Draper::ViewHelpers
  module ViewHelpers
    extend ActiveSupport::Concern

    module ClassMethods

      # Access the helpers proxy to call built-in and user-defined
      # Rails helpers from a class context.
      #
      # @return [HelperProxy] the helpers proxy
      def helpers
        StrongPresenter::ViewContext.current
      end
      alias_method :h, :helpers

    end

    # Access the helpers proxy to call built-in and user-defined
    # Rails helpers. Aliased to `h` for convenience.
    #
    # @return [HelperProxy] the helpers proxy
    def helpers
      StrongPresenter::ViewContext.current
    end
    alias_method :h, :helpers

    # Alias for `helpers.localize`, since localize is something that's used
    # quite often. Further aliased to `l` for convenience.
    def localize(*args)
      helpers.localize(*args)
    end
    alias_method :l, :localize

  end
end
