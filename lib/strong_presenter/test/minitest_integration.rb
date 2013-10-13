class StrongPresenter::TestCase
  register_spec_type(self) do |desc|
    desc < StrongPresenter::Presenter || desc < StrongPresenter::CollectionPresenter if desc.is_a?(Class)
  end
  register_spec_type(/Presenter( ?Test)?\z/i, self)
end
