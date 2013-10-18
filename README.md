# StrongPresenter

[![Gem Version](https://badge.fury.io/rb/strong_presenter.png)](http://badge.fury.io/rb/strong_presenter)
[![Build Status](https://travis-ci.org/ronalchn/strong_presenter.png?branch=master)](https://travis-ci.org/ronalchn/strong_presenter)
[![Coverage Status](https://coveralls.io/repos/ronalchn/strong_presenter/badge.png)](https://coveralls.io/r/ronalchn/strong_presenter)
[![Code Climate](https://codeclimate.com/github/ronalchn/strong_presenter.png)](https://codeclimate.com/github/ronalchn/strong_presenter)

StrongPresenter adds a layer of presentation logic to your application. The presenters also give you a strong_parameters-like syntax to specify what attributes can be read, helping you push authorization logic from the view layer back to the controller layer. The view layer can be dumber, and concentrate on page layout rather than authorization logic flow.

A number of features have been copied from Draper and refined.

## Why use Presenters?

Presenters deal with presentation, so your models can concentrate on domain logic. Instead of using a helper methods, you can implement the method in a presenter instead.

Others have used decorators for this purpose - while they can be used for presentation logic, it may cause some confusion in your application. Presenters are designed to help you to present - a market-oriented solution. Decorators are a coding pattern which can be used for presentation - a product-oriented solution.

The decorator coding pattern involves using delegation to wrap the model, adding new behaviour to the base object, possibly overriding some methods to present data in a visually appealing way. The decorator pattern not only wraps an object, but also involves keeping the decorated object acting like an instance of the base object (allowing multiple redecorations) - but this is not really what you want for presentation.

When we consider presentation, we are interested in reading the information, not further mutating the object, so we want to hide attribute setters, or other domain logic. We are also not interested in wrapping multiple layers around the object (we can use multiple still use presenters of the same object). If we want to share presentation logic between different models, we should instead use one presenter per model, including various behaviour using mixins.

While there exist other gems for presentation, we hope to provide a more natural interface to create your presenters.

## Installation

Requires Rails. Rails 3.2+ is supported (probably works on 3.0, 3.1 as well).

Add this line to your application''s Gemfile:

    gem 'strong_presenter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install strong_presenter

Or to use the edge version, add this to your Gemfile:

    gem 'strong_presenter', :github => 'ronalchn/strong_presenter'

## Usage

### Writing Presenters

Presenters are stored in `app/presenters`, they inherit from `StrongPresenter::BasePresenter` and are named based on the model they decorate. We also recommend you create an `ApplicationPresenter`.

```ruby
# app/presenters/user_presenter.rb
class UserPresenter < ApplicationPresenter
  # ...
end
```

### Accessing the Model and Helpers

As shown below, rails helpers can be accessed through `h`. You can access the model using the `object` method, or the model name (in this case `user`). For example:

```ruby
class UserPresenter < ApplicationPresenter
  presents :user
  def avatar
    h.tag :img, :src => user.avatar_url
  end
end
```

The model name is either inferred from the class name - taking `UserPresenter`, and converting the part before "Presenter" to lower case with underscores between each word, or it can be set using the `presents` method as shown above.

### Delegating Methods

If no changes are necessary, a method can be delegated to the model. The `:to` option defaults to `object`.

```ruby
class UserPresenter < ApplicationPresenter
  delegate :username, :email
end
```

### Wrapping Models with Presenters

#### Single Objects

Just pass the model to a new presenter instance:

```ruby
@user_presenter = UserPresenter.new(@user)
```

#### Collections

Pass the model to a corresponding collection presenter:

```ruby
@users_presenter = UserPresenter::Collection.new(@users)
```

To add methods to your collection presenter, inherit from `StrongPresenter::CollectionPresenter`:

```ruby
# app/presenters/users_presenter.rb
class UsersPresenter < StrongPresenter::CollectionPresenter
  def pages
    (collection.size / 20).ceil
  end
end
```

It wraps each item in the collection with the corresponding singular presenter inferred from the class name, but it can be set using the `:with` option in the constructor, or by calling `presents_with :user` (for example), in the class definition.

### Model Associations

To automatically wrap associations with a presenter, use `presents_association` or `presents_associations`:

```ruby
# app/presenters/users_presenter.rb
class UsersPresenter < StrongPresenter::CollectionPresenter
  presents_association :comments
end
```

A specific presenter can be specified using the `:with` option, otherwise it is inferred from the association. A scope can be specified using the `:scope` option. It can also yield the new presenter to a block.

### When to Wrap the Model with the Presenter

You will normally want to wrap the model with the presenter at the end of your controller action:

```ruby
class UserController < ApplicationController
  def show
    @user = User.find(params[:id])
    @user_presenter = UserPresenter.new(@user)
  end
end
```

But you can use the `presents` method to add a helper method that returns the presenter lazily:

```ruby
class UserController < ApplicationController
  presents :user, with: UserPresenter, only: :show
  def show
    @user = User.find(params[:id])
  end
end
```

If the `:with` option is not passed, it will be inferred by using the model class name. `:only` and `:except` sets the controller actions it applies to.

### Permit!

You can simply use the presenter in the view:

```ruby
Avatar: <%= @user_presenter.avatar %>
```

However, sometimes you will want to display information only if it is permitted. To do this, simply pass the attribute symbols to the `presents` method on the presenter, and it will only display it if it is permitted. This is especially powerful because it controls the display of not just the attribute value, but everything that is passed in the block.

```erb
<% fields = { :username => "Username", :name => "Name", :email => "E-mail" } %>
<% user.presents *fields.keys do |key, value| # user = @user_presenter because of the call to `presents` in the controller class %>
  <b><%= fields[key] %>:</b> <%= value %><br>
<% end %>
```

The `present` method is also available to display a single attribute:

```erb
<b>Hello <%= user.present :name %></b><br>
<% user.present :username do |value| %>
  <b>Username:</b> <%= value %><br>
<% end %>
```

To permit the display of the attributes, call `permit` on the presenter with the attribute symbols in the controller.

```ruby
class UserController < ApplicationController
  def show
    @user = User.find(params[:id])
    @user_presenter = UserPresenter.new(@user).permit :username, :name # but not :email
  end
end
```

You can also call it when using the `presents` method in the controller:

```ruby
class UserController < ApplicationController
  presents :user do |presenter|
    presenter.permit :username, :name
    presenter.permit :email if current_user.admin?
  end
  def show
    @user = User.find(params[:id])
  end
end
```

To remove authorization checks, simply call `permit!` on an instance of a presenter.

There is also a `filter` method to help you with tables:

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

We can decide what attributes to present based on a GET parameter input, for example:

```erb
<% @user_presenter.presents( params[:columns].split(',') ).each do |value| %>
  <%= content_tag :td, value %>
<% end %>
```

Because of the `permit` checks, there is no danger that private information will be revealed.

#### Permissions Paths

Association methods can be permitted by passing an array.

```rb
@article_presenter.permit :body, [:author, :name]
```

Then, presenting it:

```erb
<%= @article_presenter.present [:author, :name] %>
```

is equivalent to `@article_presenter.author.name`, except it includes the permission check.

#### Permissions Groups

Currently, each group of presenters shares a single permissions object. Therefore, each element in a collection references the same permissions object. The presenter for each association also shares the same permissions object. This means that permitting a method will permit it for all presenters in the group, and it is not possible for two presenters in the same collection to have different methods permitted.

Everytime you get a presenter through a collection or association, it will be added to the permissions group. To start a new group, you will need to initialize it yourself.

It is the intention that in version 0.2.0, permissions groups (for efficiency in a simple implementation), will be removed, and each new presenter will implement copy on write with the permissions object. This will retain efficiency where `permit` is called early before forking new presenters, but allow different permissions for each presenter. This will change the behaviour of what is considered permitted, but if `permit` is called before using the presenter, the behaviour will not change.

### Testing

#### RSpec

The specs are placed in `spec/presenters`. Add `type: :presenter` if they are placed elsewhere.

#### Isolated Tests

In tests, a view context is built to access helper methods. By default, it will create an ApplicationController and then use its view context. If you are speeding up your test suite by testing each component in isolation, you can eliminate this dependency by putting the following in your spec_helper or similar:

```ruby
StrongPresenter::ViewContext.test_strategy :fast
```

In doing so, your presenters will no longer have access to your application''s helpers. If you need to selectively include such helpers, you can pass a block:

```ruby
StrongPresenter::ViewContext.test_strategy :fast do
  include ApplicationHelper
end
```

### Generating Presenters

With StrongPresenter installed:

```sh
rails generate resource Article
```

will include a presenter.

To generate a presenter by itself:

```sh
rails generate presenter Article
```

## Acknowledgements

- [Draper](https://github.com/drapergem/draper) - a number of features from this gem have been copied and refined. Thanks!
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
