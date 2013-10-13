module StrongPresenter
  module Permissible
    extend ActiveSupport::Concern

    module ClassMethods
      # Permits all fields in the presenter for mass presentation
      #
      def permit!
        define_method(:permitted_attributes){ StrongPresenter::Permissions.all }
      end
    end

    # Sets fields which will be permitted. May be invoked multiple times.
    #
    def permit *fields
      self.permitted_attributes.merge fields if !permitted_attributes.complete?
      self
    end

    # Permits all fields
    #
    def permit!
      permitted_attributes.permit_all!
      self
    end

    # Checks which fields are visible according to what is permitted. An array is returned.
    #
    def filter *fields
      select_permitted(fields).map(&:first)
    end

    protected
    def permitted_attributes
      @permitted_attributes ||= StrongPresenter::Permissions.new
    end

    def select_permitted fields
      fields.map! do |field|
        field = Array(field)
        field[0] = field[0].to_sym
        field
      end
      fields.select! { |field| permitted_attributes.include? field[0] } if !permitted_attributes.complete?
      fields
    end

    private
    def permitted_attributes= permitted_attributes
      permitted_attributes.permit_all! if permitted_attributes.complete?
      @permitted_attributes = permitted_attributes
    end

  end
end