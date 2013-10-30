module StrongPresenter
  class Presenter
    include StrongPresenter::ViewHelpers
    include StrongPresenter::Associable
    include StrongPresenter::Delegation
    include StrongAttributes::Displayable

    include ActiveModel::Serialization
    include ActiveModel::Serializers::JSON
    include ActiveModel::Serializers::Xml

    # Constructs the presenter, taking 1 argument for the object being wrapped. For example:
    #
    #   user_presenter = UserPresenter.new @user
    #
    # A block can also be passed to use the presenter. For example:
    #
    #   <% UserPresenter.new @user do |user_presenter| %>
    #     Username: <%= user_presenter.username %>
    #   <% end %>
    #

    def initialize(object)
      @object = object
      yield self if block_given?
    end

    # deprecated
    alias_method :presents, :displays
    alias_method :present, :display

    delegate :to_s

    # In case object is nil
    delegate :present?, :blank?

    # ActiveModel compatibility
    # @private
    def to_model
      self
    end

    # @return [Hash] the object's attributes, sliced to only include those
    # implemented by the presenter.
    def attributes
      object.attributes.select {|attribute, _| respond_to?(attribute) }
    end

    # ActiveModel compatibility
    delegate :to_param, :to_partial_path

    # ActiveModel compatibility
    singleton_class.delegate :model_name, to: :object_class

    protected
    def object
      @object
    end

    class << self
      def inferred_presenter(object)
        Inferrer.new(object.class.name).inferred_class { |name| "#{name}Presenter" } or raise StrongPresenter::UninferrablePresenterError.new(self)
      end

      protected
      def alias_object_to_object_class_name
        if object_class?
          alias_method object_class.name.underscore, :object
          private object_class.name.underscore
        end
      end

      def set_presenter_collection
        collection_presenter = get_collection_presenter
        const_set "Collection", collection_presenter # will overwrite if constant only defined in superclass
      end

      private
      def inherited(subclass)
        subclass.alias_object_to_object_class_name
        subclass.set_presenter_collection
        super
      end

      def get_collection_presenter
        collection_presenter = Inferrer.new(name).chomp("Presenter").inferred_class {|name| "#{name.pluralize}Presenter"}
        return collection_presenter unless collection_presenter.nil? || collection_presenter == self
        Class.new(StrongPresenter::CollectionPresenter).presents_with(self)
      end

      # Returns the source class corresponding to the presenter class, as set by
      # {presents}, or as inferred from the presenter class name (e.g.
      # `ProductPresenter` maps to `Product`).
      #
      # @return [Class] the source class that corresponds to this presenter.
      def object_class
        @object_class ||= Inferrer.new(name).chomp("Presenter").inferred_class or raise UninferrableSourceError.new(self)
      end

      # Checks whether this presenter class has a corresponding {object_class}.
      def object_class?
        !!(@object_class ||= Inferrer.new(name).chomp("Presenter").inferred_class)
      end

      # Sets the model presented by the class
      #
      def presents name
        @object_class = name.to_s.camelize.constantize
        alias_object_to_object_class_name
      end

    end
  end
end

