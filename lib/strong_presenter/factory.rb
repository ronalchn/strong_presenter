module StrongPresenter
  class Factory
    # Creates a presenter factory.
    #
    # @option options [Presenter, CollectionPresenter] :with (nil)
    #   presenter class to use. If nil, it is inferred from the object
    #   passed to {#wrap}.
    def initialize(options = {})
      options.assert_valid_keys(:with)
      @presenter_class = options.delete(:with)
    end

    # Wraps an object with a presenter, inferring whether to create a singular or collection
    # presenter from the type of object passed.
    #
    # @param [Object] object
    #   object to present.
    # @return [Presenter, CollectionPresenter] the presenter.
    def wrap(object)
      return nil if object.nil?
      Worker.new(presenter_class, object).call { |presenter| yield presenter if block_given? }
    end

    private

    attr_reader :presenter_class

    # @private
    class Worker
      def initialize(presenter_class, object)
        @presenter_class = presenter_class
        @object = object
        @presenter_class = presenter_class::Collection if collection? && !presenter_class.nil? && (presenter_class < StrongPresenter::Presenter)
      end

      def call
        presenter.new(object) { |presenter| yield presenter if block_given? }
      end

      def presenter
        return presenter_class if presenter_class
        return object_presenter if object_presenter
        return StrongPresenter::CollectionPresenter if collection?
        raise StrongPresenter::UninferrablePresenterError.new(object.class)
      end

      private

      attr_reader :presenter_class, :object

      def object_presenter
        @object_presenter = @object_presenter.nil? ? get_object_presenter : @object_presenter
      end

      def get_object_presenter
        StrongPresenter::Presenter.inferred_presenter(object)
      rescue NameError => error
        false
      end

      def collection?
        object.is_a?(Enumerable) or is_a?("ActiveRecord::Associations::CollectionProxy") # or any other wrappers
      end

      # Checks if object is an instance of klass, false in case klass does not exist.
      def is_a? klass
        object.is_a? klass.constantize
      rescue NameError
        false
      end
    end
  end
end

