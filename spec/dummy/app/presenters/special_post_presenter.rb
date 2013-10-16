class SpecialPostPresenter < StrongPresenter::Presenter
  presents :post

  delegate :id, :title
end
