# StrongPresenter Changelog

## 0.2.0

This release focuses on tightening up security of the permit interface, along with a number of bug fixes.

- Renamed `permit` to `permit!` in Presenter, CollectionPresenter, Permissible
- Renamed `filter` to `select_permitted` in Presenter, CollectionPresenter, Permissible
- Permitted paths are only prefixes with wildcard endings if specified explicitly
  - `[:comments, :*]` permits all the methods in each comment in the comments association, but not further associations
  - `[:comments, :**]` permits all methods in all associations, no matter how deep (for example it permits `[:comments, :user, :username]`)
- Wildcards disabled for tainted paths, tainted paths are only permitted if the exact path has been permitted
  - a path is tainted if any element in the array is tainted, for example `params[:extra_column].split(',')` is tainted
- `permit_all!` class method removed - use an initializer instead
- Permissions grouping removed - the permissions of each presenter is independent, with copy on write semantics.
  - but permitting on a presenter will propagate permissions to the presenters of associations or collection items. This can be inefficient if an object has many associations or the collection has many items. It is recommended that `permit!` is called before associations or collection items are loaded
- Added `reload!`, which will reset the cache on association or collection presenters. This might be used if the underlying object has changed.

## 0.1.0

- Copied features from Draper gem (thanks):
  - spec/spec_helper.rb, spec/integration, spec/dummy - much easier for me, since I have difficulties trying to get a dummy app working.
  - ViewContext, HelperProxy - compared to my HelperProxy trying to include various rails modules, this exposes methods like `current_user` as well.
  - test integration - ties in with ViewContext.
  - Gemfile, .travis.yml, .yardopts, Rakefile, Guardfile, .rspec, tasks
  - Generators
- Features derived from the Draper gem with substantial modifications
  - factory - remove many options, some simplifications.
  - DecoratesAssigned -> ControllerAdditions - :only, :except options, execute block instead of passing :context-like options.
  - CollectionDecorator -> CollectionPresenter
  - Associations -> Associable
- Other features added
  - *Presenter::Collection - constant automatically added which points to the corresponding collection presenter. If this does not exist, a subclass of StrongPresenter::CollectionPresenter is dynamically created.
  - Permissible, Permissions - `permit`, `permit!`, `filter` interface separated into a separate Permissible module. The Permissions class just stores attributes that have been permitted

## 0.0.1

- Allows presenters in `app/presenters` to wrap models and expose a read-only interface.
- `permit` interface to mark attributes with a `presents` method on each presenter, which yields the value of permitted attributes to a block.
