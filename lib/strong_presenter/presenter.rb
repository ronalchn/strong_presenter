module StrongPresenter
  class Presenter
    include StrongPresenter::ViewHelpers
    include StrongPresenter::Permissible
    extend StrongPresenter::Delegation

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

    # Performs mass presentation - if it is allowed, subject to `permit`. To permit all without checking, call `permit!` first.
    #
    # Presents and returns the result of each field in the argument list. If a block is given, then each result
    # is passed to the block. Each field is presented by calling the method on the presenter.
    #
    #   user_presenter.presents :username, :email # returns [user_presenter.username, user_presenter.email]
    #
    # Or with two arguments, the name of the field is passed first:
    #
    #   <ul>
    #     <% user_presenter.presents :username, :email, :address do |field, value| %>
    #       <li><%= field.capitalize %>: <% value %></li>     
    #     <% end %>
    #   </ul>
    #
    # If only the presented value is desired, use `each`:
    #
    #   <% user_presenter.presents(:username, :email).each do |value| %>
    #     <td><%= value %></td>
    #   <% end %>
    #
    # A field can have arguments in an array:
    #
    #   user_presenter.presents :username, [:notifications, :unread] # returns [user_presenter.username, user_presenter.notifications(:unread)]
    #
    # Notice that this interface allows you to concisely put authorization logic in the controller, with a dumb view layer:
    #
    #   # app/controllers/users_controller.rb
    #   class UsersController < ApplicationController
    #     def visible_params
    #       @visible_params ||= begin
    #         field = [:username]
    #         field << :email if can? :read_email, @user
    #         field << :edit_link if can? :edit, @user
    #       end
    #     end
    #     def show
    #       @users_presenter = UserPresenter.wrap_each(User.all).permit!
    #     end
    #   end
    #
    #   # app/views/users/show.html.erb
    #   <table>
    #     <tr>
    #       <% visible_params.each do |field| %>
    #         <th><%= field %></th>
    #       <% end %>
    #     </tr>
    #     <% @users_presenter.each do |user_presenter| %>
    #       <tr>
    #         <% user_presenter.presents(*visible_params).each do |value| %>
    #           <td><%= value %></td>
    #         <% end %>
    #       </tr>
    #     <% end %>
    #   </table>
    #
    def presents *attributes
      select_permitted(attributes).map do |args|
        # TODO: drill down while args[0] is association (when associations feature added)
        value = self.public_send *args
        yield args[0], value if block_given?
        value
      end
    end

    # Same as presents, but for a single attribute. The differences are:
    #   - the return value is not in an Array
    #   - passes the value only (without attribute key as the 1st argument) to a block
    def present field
      presents field do |key, value|
        yield value if block_given?
      end.first
    end

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
        name = object.class.name
        raise NameError if name.nil?
        begin
          "#{name}Presenter".constantize
        rescue NameError => error
          raise if name && !error.missing_name?(name)
          raise StrongPresenter::UninferrablePresenterError.new(self)
        end
      end

      protected
      def alias_object_to_object_class_name
        if object_class?
          alias_method object_class.name.underscore, :object
          private object_class.name.underscore
        end
      end

      def set_presenter_collection
        const_set "Collection", collection_presenter
      end

      private
      def inherited(subclass)
        subclass.alias_object_to_object_class_name
        subclass.set_presenter_collection
        super
      end

      def collection_presenter
        name = collection_presenter_name
        name.constantize
      rescue NameError => error
        raise if name && !error.missing_name?(name)
        Class.new(StrongPresenter::CollectionPresenter).presents_with(self)
      end

      def object_class_name
        raise NameError if name.nil? || name.demodulize !~ /.+Presenter$/
        name.chomp("Presenter")
      end

      def inferred_object_class
        name = object_class_name
        name.constantize
      rescue NameError => error
        raise if name && !error.missing_name?(name)
        raise StrongPresenter::UninferrableSourceError.new(self)
      end

      def collection_presenter_name
        plural = object_class_name.pluralize
        raise NameError if plural == object_class_name
        "#{plural}Presenter"
      end

      # Returns the source class corresponding to the presenter class, as set by
      # {presents}, or as inferred from the presenter class name (e.g.
      # `ProductPresenter` maps to `Product`).
      #
      # @return [Class] the source class that corresponds to this presenter.
      def object_class
        @object_class ||= inferred_object_class
      end

      # Checks whether this presenter class has a corresponding {object_class}.
      def object_class?
        object_class
      rescue StrongPresenter::UninferrableSourceError
        false
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

