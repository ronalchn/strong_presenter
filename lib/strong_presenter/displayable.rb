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
        args = Array(args).dup
        value = self
        until args.empty? do
          arity = value.method(args[0]).arity
          if arity >= 0
            value = value.public_send *args.slice!(0, arity+1)
          else
            value = value.public_send *args
            break
          end
        end
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
