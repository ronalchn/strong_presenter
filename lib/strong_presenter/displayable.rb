module StrongPresenter
  module Displayable
    extend ActiveSupport::Concern
    include StrongPresenter::Permissible

    # Displays the result of each method call if permitted. To permit all without checking, call `permit!` first.
    #
    # Calls and returns the result of each method call in the argument list. If a block is given, then each result
    # is passed to the block.
    #
    #   user.displays :username, :email # returns [user.username, user.email]
    #
    # Or with two arguments, the name of the field is passed first:
    #
    #   <ul>
    #     <% user.displays :username, :email, :address do |field, value| %>
    #       <li><%= field.capitalize %>: <% value %></li>     
    #     <% end %>
    #   </ul>
    #
    # If only the presented value is desired, use `each`:
    #
    #   <% user.displays(:username, :email).each do |value| %>
    #     <td><%= value %></td>
    #   <% end %>
    #
    # Arguments can be included in an array:
    #
    #   user.displays :username, [:notifications, :unread] # returns [user.username, user.notifications(:unread)]
    #
    def displays *attributes
      select_permitted(*attributes).map do |args|
        args = Array(args)
        obj = self # drill into associations
        while (args.size > 1) && obj.class.respond_to?(:presenter_associations, true) && obj.class.send(:presenter_associations).include?(args[0]) do
          obj = obj.public_send args.slice!(0)
        end
        value = obj.public_send *args # call final method with args
        yield args[0], value if block_given?
        value
      end
    end

    # Same as displays, but for a single attribute. The differences are:
    #   - the return value is not in an Array
    #   - passes the value only (without attribute key as the 1st argument) to a block
    def display field
      displays field do |key, value|
        yield value if block_given?
      end.first
    end
  end
end
