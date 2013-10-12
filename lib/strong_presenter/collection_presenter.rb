module StrongPresenter
  class CollectionPresenter
    include Enumerable
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
    attr_reader :presenter_class

    # @return the collection being presented.
    attr_reader :object

    # Wraps the given item.
    def wrap_item(item)
      item_presenter.new(item).tap do |presenter|
        presenter.send :permitted_attributes=, permitted_attributes # item's permitted_attributes is linked to collection
      end
    end

    # @return [Array] the items being presented
    def collection
      @collection ||= object.map{|item| wrap_item(item)}
    end

    private
    def item_presenter
      presenter_class || self.inferred_presenter_class
    end

    class << self
      private
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
        raise StrongPresenter::UninferrableSourceError.new(self)
      end
    end
  end
end
