module StrongPresenter

  # Methods for defining presenter associations
  module Associable
    extend ActiveSupport::Concern
    include StrongAttributes::Permissible

    module ClassMethods
      #   Automatically wraps multiple associations.
      #   @param [Symbol] association
      #     name of the association to wrap.
      #   @option options [Class] :with
      #     the presenter to apply to the association.
      #   @option options [Symbol] :scope
      #     a scope to apply when fetching the association.
      #   @yield
      #     block executed when association presenter is initialized, in
      #     the context of the parent presenter instance (instance_exec-ed)
      #   @yieldparam [Presenter] the association presenter
      #   @return [void]
      def presents_association(association, options = {})
        options.assert_valid_keys(:with, :scope)
        association = association.to_sym
        options[:with] = Associable.object_association_class(object_class, association) unless options.has_key? :with
        presenter_associations[association] ||= StrongPresenter::PresenterAssociation.new(association, options) do |presenter|
          presenter.link_permissions self, association
          yield presenter if block_given?
        end
        define_method(association) do
          presenter_associations[association] ||= self.class.send(:presenter_associations)[association].wrap(self)
        end
      end

      # @overload presents_associations(*associations, options = {})
      #   Automatically wraps multiple associations.
      #   @param [Symbols*] associations
      #     names of the associations to wrap.
      #   @option options [Class] :with
      #     the presenter to apply to the association.
      #   @option options [Symbol] :scope
      #     a scope to apply when fetching the association.
      #   @yield
      #     block executed when association presenter is initialized, in
      #     the context of the parent presenter instance (instance_exec-ed)
      #   @yieldparam [Presenter] the association presenter
      #   @return [void]
      def presents_associations(*associations)
        options = associations.extract_options!
        options.assert_valid_keys(:with, :scope)
        associations.each { |association| presents_association(association, options) {|presenter| yield if block_given?} }
      end

      private
      def presenter_associations
        @presenter_associations ||= {}
      end
    end

    # Permits given attributes, with propagation to associations.
    def permit! *attribute_paths
      super
      attribute_paths.each do |path| # propagate permit to associations
        path = Array(path)
        if path == [:**]
          presenter_associations.each_value { |presenter| presenter.permit! [:**]}
        elsif path.size>1
          association = path[0].to_sym
          presenter_associations[association].permit! path.drop(1) if presenter_associations.has_key?(association)
        end
      end
      self
    end

    # Resets association presenters - clears the cache
    def reload!
      @presenter_associations.clear
      self
    end

    private
    def presenter_associations
      @presenter_associations ||= {}
    end

    protected

    # infer association class if possible
    def self.object_association_class(object_class, association)
      klass, collection = get_orm_association_info(object_class, association)
      return nil if klass.nil?
      "#{klass}Presenter".constantize
    rescue NameError
      get_collection_presenter(klass) if collection # else nil
    end

    def self.get_orm_association_info(object_class, association)
      if descendant_of(object_class, "ActiveRecord::Reflection")
        object_class.reflect_on_association(association).instance_eval { [klass, collection?] }
      else
        nil
      end
    end

    def self.descendant_of(object_class, klass)
      object_class.ancestors.include? klass.constantize
    rescue NameError
      false
    end

    def self.get_collection_presenter(klass)
      "#{"#{klass}".pluralize}Presenter".constantize
    rescue NameError
      StrongPresenter::CollectionPresenter
    end
  end
end

