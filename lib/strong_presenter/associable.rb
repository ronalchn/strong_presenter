module StrongPresenter

  # Methods for defining presenter associations
  module Associable
    extend ActiveSupport::Concern

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
        options[:with] = Associable.object_association_class(object_class, association) unless options.has_key? :with
        presenter_associations[association] ||= StrongPresenter::PresenterAssociation.new(association, options) do |presenter|
          presenter.send :link_permitted_attributes, permitted_attributes, self.send(:permissions_prefix) + [association]
          yield if block_given?
        end
        define_method(association) do
          self.class.send(:presenter_associations)[association].wrap(self)
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

    protected

    # obtain class of association from object
    def self.object_association_class(object_class, association)
      if self.descendant_of(object_class, "ActiveRecord::Reflection")
        association_class = object_class.reflect_on_association(association).klass
      else
        return nil
      end
      "#{association_class}Presenter".constantize
    rescue NameError
      nil
    end

    def self.descendant_of(object_class, klass)
      object_class.ancestors.include? klass.constantize
    rescue NameError
      false
    end
  end
end

