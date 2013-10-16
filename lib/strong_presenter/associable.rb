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
        begin
          association_class = object_class.reflect_on_associations[association].klass
          options[:with] = "#{association_class}Presenter".constantize # depends on ActiveRecord
        rescue NameError
        end unless options.has_key? :with
        presenter_associations[association] ||= StrongPresenter::PresenterAssociation.new(association, options) do |presenter|
          presenter.send :link_permitted_attributes, permitted_attributes, self.send(:permissions_prefix) + [association]
          yield if block_given?
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

      def presenter_associations
        @presenter_associations ||= {}
      end
    end

    private


    def presenter_associations
      @presenter_associations ||= {}
    end
  end
end
