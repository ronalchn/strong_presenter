# StrongPresenter Changes

## 0.1.0

- Copied features from Draper gem (thanks):
  - spec/spec_helper.rb, spec/integration, spec/dummy - much easier for me, since I have difficulties trying to get a dummy app working.
  - ViewContext, HelperProxy - compared to my HelperProxy trying to include various rails modules, this expose methods like `current_user` as well.
  - test integration - ties in with ViewContext.
  - Gemfile, .travis.yml, .yardopts, Rakefile, Guardfile, .rspec
- Features from Draper gem with substantial modifications
  - factory - remove many options, some simplifications.
  - DecoratesAssigned -> ControllerAdditions - :only, :except options, execute block instead of passing :context-like options.
  - CollectionDecorator -> CollectionPresenter
- Other features added
  - *Presenter::Collection - constant automatically added which points to the corresponding collection presenter. If this does not exist, a subclass of StrongPresenter::CollectionPresenter is dynamically created.
  - Permissible, Permissions - `permit`, `permit!`, `filter` interface separated into a separate Permissible module. The Permissions class just stores attributes that have been permitted

## 0.0.1

- Allows presenters in `app/presenters` to wrap models and expose a read-only interface.
- `permit` interface to mark attributes with a `presents` method on each presenter, which yields the value of permitted attributes to a block.
