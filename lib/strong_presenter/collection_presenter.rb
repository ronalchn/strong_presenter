module StrongPresenter
  class CollectionPresenter
    include Enumerable
    include StrongPresenter::ViewHelpers
    include StrongPresenter::Permissible
    extend StrongPresenter::Delegation

    array_methods = Array.instance_methods - Object.instance_methods
    delegate :==, :as_json, *array_methods, to: :collection

    # @param [Enumerable] object
    #   collection to present
    def initialize(object, options = {})
      options.assert_valid_keys(:with)
      @object = object
      @presenter_class = options[:with]
    end

    def to_s
      "#<#{self.class.name} of #{presenter_class || "inferred presenters"} for #{object.inspect}>"
    end

    protected
    # @return [Class] the presenter class used to present each item, as set by
    #   {#initialize}.
    def presenter_class
      @presenter_class = @presenter_class.nil? ? self.class.send(:presenter_class) : @presenter_class
    end

    def item_presenter(item)
      return presenter_class if presenter_class
      StrongPresenter::Presenter.inferred_presenter(item)
    end

    # @return the collection being presented.
    attr_reader :object

    # Wraps the given item.
    def wrap_item(item)
      item_presenter(item).new(item).tap do |presenter|
        presenter.send :link_permitted_attributes, permitted_attributes # item's permitted_attributes is linked to collection
      end
    end

    # @return [Array] the items being presented
    def collection
      @collection ||= object.map{|item| wrap_item(item)}
    end

    class << self
      # Sets the presenter used to wrap models in the collection
      def presents_with presenter
        @presenter_class = presenter
        self
      end

      protected
      def set_item_presenter_collection
        name = presenter_class_name # singular Presenter name
        if const_defined? name # exists?
          presenter = name.constantize
          if presenter::Collection.name.demodulize == "Collection"
            presenter.send :remove_const, :Collection
            presenter.send :const_set, "Collection", self
          end
        end
      rescue NameError => error
      end

      private
      def inherited(subclass)
        subclass.set_item_presenter_collection
        super
      end

      def presenter_class_name
        raise NameError if name.nil? || name.demodulize !~ /.+Presenter$/
        plural = name.chomp("Presenter")
        singular = plural.singularize
        raise NameError if plural == singular
        "#{singular}Presenter"
      end

      def inferred_presenter_class
        name = presenter_class_name
        name.constantize
      rescue NameError => error
        raise if name && !error.missing_name?(name)
        raise StrongPresenter::UninferrablePresenterError.new(self)
      end

      def presenter_class
        @presenter_class ||= inferred_presenter_class
      rescue StrongPresenter::UninferrablePresenterError
        false
      end

    end
  end
end
