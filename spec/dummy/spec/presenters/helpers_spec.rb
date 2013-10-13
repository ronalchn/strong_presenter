require 'spec_helper'

describe "A presenter spec" do
  it "can access helpers through `helper`" do
    expect(helper.content_tag(:p, "Help!")).to eq "<p>Help!</p>"
  end

  it "can access helpers through `helpers`" do
    expect(helpers.content_tag(:p, "Help!")).to eq "<p>Help!</p>"
  end

  it "can access helpers through `h`" do
    expect(h.content_tag(:p, "Help!")).to eq "<p>Help!</p>"
  end

  it "gets the same helper object as a presenter" do
    presenter = StrongPresenter::Presenter.new(Object.new)

    expect(helpers).to be presenter.helpers
  end
end
