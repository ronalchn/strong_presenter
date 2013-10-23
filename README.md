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

Add this line to your application&#39;s Gemfile:

    gem 'strong_presenter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install strong_presenter

Or to use the edge version, add this to your Gemfile:

    gem 'strong_presenter', :github => 'ronalchn/strong_presenter'

## Usage

### Writing Presenters

Presenters are stored in `app/presenters`, they inherit from `StrongPresenter::Presenter` and are named based on the model they decorate. We also recommend you create an `ApplicationPresenter`.

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

It wraps each item in the collection with the corresponding singular presenter inferred from the class name, but it can be set using the `:with` option in the constructor, or by calling `presents_with :user` (for example), in the class definition. The `::Collection` constant of each presenter will automatically be set to the collection presenter with a matching plural name.

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

Subsequently, in our view, we can use:

```erb
  Username: <%= user.username %><br>
  Email: <%= user.email %><br>
```

If the `:with` option is not passed, it will be inferred by using the model class name. `:only` and `:except` sets the controller actions it applies to.

### Permit! and `present`

#### Basics

You can simply use the presenter in the view:

```ruby
Avatar: <%= @user_presenter.avatar %>
```

However, sometimes you will want to display information only if it is permitted. To do this, simply pass the attribute symbols to the `presents` method on the presenter, and it will only display it if it is permitted. This is quite useful because it controls the display of not just the attribute value, but everything that is passed in the block. If no block is given, the results are returned in an array.

```erb
<% fields = { :username => "Username", :name => "Name", :email => "E-mail" } %>
<% @user_presenter.presents *fields.keys do |key, value| %>
  <b><%= fields[key] %>:</b> <%= value %><br>
<% end %>
```

The `present` method is also available to display a single attribute. If no block is given, the result is returned, ready to display.

```erb
<b>Hello <%= user.present :name %></b><br>
<% user.present :username do |value| %>
  <b>Username:</b> <%= value %><br>
<% end %>
```

To permit the display of the attributes, call `permit!` on the presenter with the attribute symbols in the controller.

```ruby
class UserController < ApplicationController
  def show
    @user = User.find(params[:id])
    @user_presenter = UserPresenter.new(@user).permit! :username, :name # but not :email
  end
end
```

You can also call it when using the `presents` method in the controller:

```ruby
class UserController < ApplicationController
  presents :user do |presenter|
    presenter.permit! :username, :name
    presenter.permit! :email if current_user.admin?
  end
  def show
    @user = User.find(params[:id])
  end
end
```

There is also a `select_permitted` method to help you with tables. For example, we use `select_permitted` below to check which of the columns are visible.

```erb
<% fields = { :username => "Username", :name => "Name", :email => "E-mail" } %>
<table>
  <tr>
    <% @users_presenter.select_permitted( *fields.keys ) do |key| %>
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

We can decide what attributes to present based on a GET parameter input, for example:

```erb
<% @user_presenter.presents( params[:columns].split(',') ).each do |value| %>
  <%= content_tag :td, value %>
<% end %>
```

Because of the we permit each attribute individually, there is no danger that private information will be revealed.

#### Associations - Permissions Paths

We can permit association attributes by passing an array of symbols. For example, we might normally get an Article&#39;s author using `@article.author.name`. If we permit it:

```ruby
@article_presenter.permit! [:author, :name]
```

then we can use the `present` method to display it:

```erb
<% @article_presenter.present [:author, :name] do |value| %>
  By <%= value %>
<% end %>
```

It is also possible to include arguments. If our presenter method takes 1 argument:

```ruby
class ArticlePresenter < StrongPresenter::Presenter
  def comment_text(index)
    object.comments[index].text
  end
end
```

Our view can call the method using:

```erb
<% @article_presenter.permit! [:comment_text, 3] %>
<%= @article_presenter.present [:comment_text, 3] # this is displayed %>
<%= @article_presenter.present [:comment_text, 4] # this is not %>
```

Basically, if the first element is an association, the next element will be the method name instead, and so on. When the final method is determined, extra elements in the array are passed as arguments.

When considering whether the permission path (including arguments) is permitted, it is indifferent to the difference between strings and symbols. So permitting a particular string argument will also permit the symbol argument.

#### Wildcards

To permit every attribute in a presenter, we can use wildcards. For example, to allow the display of all attributes in the article, we can call:

```ruby
@article_presenter.permit! :*
```

We can then present any attribute:

```ruby
@article_presenter.present :text
```

However, association attributes will not be permitted, for example, `@article_presenter.author.name`. To allow those, we can use the wildcard in an array:

```ruby
@article_presenter.permit! [:author, :*]
```

It is also possible to permit all association attributes:

```ruby
@article_presenter.permit! :**
```

Note that the wildcard can only be used as the last element, so for example, `[:*, :name]` is not treated as a wildcard.

Instead of the single wildcard `:*`, we can simply call `permit_all!` on the presenter.

Any attribute permitted by a wildcard will show up using the `presents` method, except when the argument is tainted. For example, if we used `@article_presenter.permit! :**`, and in our view, had:

```erb
<% @article_presenter.presents :title, "subtitle".taint, [:author, :name].taint, ["author".taint, :email], :text do |value| %>
  <%= value %><br>
<% end %>
```

then `:title` and `:text` attributes will be displayed, but the other tainted attributes will not be displayed. For example, attributes constructed using the `params` hash will be tainted. This is a security measure to prevent a bug similar to the mass-assignment vulnerability, where an arbitrary presenter method can be called.

#### Association Permissions

Association presenters will automatically inherit the permissions of its parent, and any new permissions will be propagated to the association presenter. For example:

```ruby
@article_presenter.permit! [:author, :name]
@author_presenter = @article_presenter.author
@author_presenter.present(:name) # this is permitted
@article_presenter.permit! [:author, :email]
@author_presenter.present(:email) # now this is also permitted
```

Attributes permitted by an item in a collection will not be permitted on the siblings:

```ruby
@articles_presenter[0].permit! :author
@articles_presenter[1].present(:author) # not permitted
```

### Testing

#### RSpec

The specs are placed in `spec/presenters`. Add `type: :presenter` if they are placed elsewhere.

#### Isolated Tests

In tests, a view context is built to access helper methods. By default, it will create an ApplicationController and then use its view context. If you are speeding up your test suite by testing each component in isolation, you can eliminate this dependency by putting the following in your spec_helper or similar:

```ruby
StrongPresenter::ViewContext.test_strategy :fast
```

In doing so, your presenters will no longer have access to your application&#39;s helpers. If you need to selectively include such helpers, you can pass a block:

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
