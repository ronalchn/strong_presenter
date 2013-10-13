require 'minitest_helper'

describe "A presenter test" do
  it "can access helpers through `helper`" do
    assert_equal "<p>Help!</p>", helper.content_tag(:p, "Help!")
  end

  it "can access helpers through `helpers`" do
    assert_equal "<p>Help!</p>", helpers.content_tag(:p, "Help!")
  end

  it "can access helpers through `h`" do
    assert_equal "<p>Help!</p>", h.content_tag(:p, "Help!")
  end

  it "gets the same helper object as a presenter" do
    presenter = StrongPresenter::Presenter.new(Object.new)

    assert_same presenter.helpers, helpers
  end
end
