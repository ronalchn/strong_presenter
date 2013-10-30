module StrongPresenter
  class CollectionPresenter
    include Enumerable
    include StrongPresenter::ViewHelpers
    include StrongPresenter::Delegation
    include StrongAttributes::Permissible

    array_methods = Array.instance_methods - Object.instance_methods
    delegate :==, :as_json, *array_methods, to: :collection

    # @param [Enumerable] object
    #   collection to present
    def initialize(object, options = {})
      options.assert_valid_keys(:with)
      @object = object
      @presenter_class = options[:with]

      yield self if block_given?
    end

    def to_s
      "#<#{self.class.name} of #{presenter_class || "inferred presenters"} for #{object.inspect}>"
    end

    # Permits given attributes, with propagation to collection items.
    def permit! *attribute_paths
      super
      @collection.each { |presenter| presenter.permit! *attribute_paths } unless @collection.nil?
      self
    end

    # Resets item presenters - clears the cache
    def reload!
      @collection = nil
      self
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
        presenter.link_permissions self # item's permitted_attributes is linked to collection
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
        collection = self
        presenter_class.instance_exec do
          unless nil?
            if !const_defined? :Collection
              const_set :Collection, collection
            elsif self::Collection.name.demodulize == "Collection"
              remove_const :Collection
              const_set :Collection, collection
            end
          end
        end
      rescue NameError => error
      end

      private
      def inherited(subclass)
        subclass.set_item_presenter_collection
        super
      end

      def inferred_presenter_class
        presenter_class = Inferrer.new(name).chomp("Presenter").inferred_class { |name| "#{name.singularize}Presenter" }
        presenter_class == self ? nil : presenter_class
      end

      def presenter_class
        @presenter_class ||= inferred_presenter_class
      end

    end
  end
end
