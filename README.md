[![Gem Version](https://badge.fury.io/rb/strong_presenter.png)](http://badge.fury.io/rb/strong_presenter)
[![Build Status](https://travis-ci.org/ronalchn/strong_presenter.png?branch=master)](https://travis-ci.org/ronalchn/strong_presenter)
[![Dependency Status](https://gemnasium.com/ronalchn/strong_presenter.png)](https://gemnasium.com/ronalchn/strong_presenter)
[![Coverage Status](https://coveralls.io/repos/ronalchn/strong_presenter/badge.png)](https://coveralls.io/r/ronalchn/strong_presenter)
[![Code Climate](https://codeclimate.com/github/ronalchn/strong_presenter.png)](https://codeclimate.com/github/ronalchn/strong_presenter)

# StrongPresenter

StrongPresenter lets you add presenters to your application, along with strong_parameters-inspired permit logic to handle mass presentations, where each user may have permision to view different fields.

Adding an explicit `permit` interface allows authorization logic to be pushed back from the view to the controller where it probably belongs. This allows the view to concentrate on laying out the webpage, rather than deciding whether each of the components should be displayed.

When displaying a datatable, there is no need to call `can? :read_email_column, @user` in both the table headings, and as each row is displayed. The permission check can be performed once in the controller.

This gem is opinionated. It puts presenters in `app/presenters`, not `app/decorators`, because not all decorators are presenters. Presenters should be providing a read-only interface to a model - variable setters should not be delegated through the presenter. On the other hand, decorators add features to a model, and can very well delegate setters methods to the model. We should not mix presenters with general-purpose decorators. By default, these presenters are also not decorators - because each presenter hides unnecessary methods on the base object, a presenter will, by default, hide the methods of any other presenter it is stacked on top of. To share common presenter methods, package them in modules to be included.

While there exist other presenter gems, we hope to provide a more natural interface to create your presenters.

## Installation

Requires Rails. Rails 3.2+ is supported (probably works on 3.0, 3.1 as well).

Add this line to your application's Gemfile:

    gem 'strong_presenter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install strong_presenter

## Usage

Create a new presenter:

```ruby    
class ApplicationPresenter < StrongPresenter::BasePresenter
end

class UserPresenter < ApplicationPresenter
  presents :user
  delegate :username, :name, :email, to: :user

  def avatar
    h.tag :img, :src => user.avatar_url
  end
end
```

Use the presenter on your object in your controller

```ruby
class UserController < ApplicationController
  def show
    @user = User.find(params[:id])
    @user_presenter = UserPresenter.new(@user).permit *visible_attributes
  end

  private
  def visible_attributes
    [:username] + (can?(:read_private_details, @user) ? [:name, :email] : [])
  end
end
```

Use the presenter in the view:

```ruby
Avatar: <%= @user_presenter.avatar %>
```

Or use mass presentation to present multiple attributes at once. Notice that if `visible_attributes`
does not include name or email, they will not show. The advantage is that authorization logic
remains in the controller where it arguably belongs.

```erb
<% fields = { :username => "Username", :name => "Name", :email => "E-mail" } %>
<% @user_presenter.presents *fields.keys do |key, value| %>
  <b><%= fields[key] %>:</b> <%= value %><br>
<% end %>
```

The `presents` method will only present those attributes which have been permitted. In contrast, a method
such as `avatar` on the presenter will not check if the attribute is permitted. To check this, the `presents`
method can be used. For example:

```erb
<% @user_presenter.presents(:avatar).each do |presented_avatar| %>
  <%= presented_avatar %>
<% end %>
```

In this case, since `permit` was not passed `:avatar`, it will not be presented. To remove authorization checks
from mass presentations, simply call `permit!` on an instance of a presenter, or on the class (to disable for all instances).

We can get the corresponding presenter for a collection using the `Collection` constant:

```ruby
  @users_presenter = UserPresenter::Collection.new(@users).permit( *visible_attributes )
```

Then the view can use each presenter, to display only the columns a user is permitted to view.

```erb
<% fields = { :username => "Username", :name => "Name", :email => "E-mail" } %>
<table>
  <tr>
    <% @users_presenter.filter( *fields.keys ) do |key| %>
      <th><%= fields[key] %></th>
    <% end %>
  </tr>
  <% @users_presenter.each do |user_presenter| %>
    <tr>
      <% user_presenter.presents( *fields.keys ).each do |value| %>
        <%= content_tag :td, value %>
      <% end %>
    </tr>
  <% end %>
</table>
```

Here, we use filter to check which of the columns are visible, just like `presents` does. It returns an
array of only the visible columns, and we use our `fields` hash to label it.

This also allows mass presentation based on GET parameter input, for example:

```erb
<% user_presenter.presents( params[:columns].split(',') ).each do |value| %><%= content_tag :td, value %><% end %>
```

Because of the `permit` checks, there is no danger that private information will be revealed.

## Acknowledgements

- [Draper](https://github.com/drapergem/draper) - some features/code will be copied from this gem. Thanks!
- https://github.com/railscasts/287-presenters-from-scratch/

## License

Mozilla Public License Version 2.0

Free to use in open source or proprietary applications, with the caveat that any source code changes or additions to files covered under MPL V2 can only be distributed under the MPL V2 or secondary license as described in the full text.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
