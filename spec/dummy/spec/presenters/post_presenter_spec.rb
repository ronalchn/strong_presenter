require 'spec_helper'

describe PostPresenter do
  let(:presenter) { PostPresenter.new(object) }
  let(:object) { Post.create }

  it "can use built-in helpers" do
    expect(presenter.truncated).to eq "Once upon a..."
  end

  it "can use built-in private helpers" do
    expect(presenter.html_escaped).to eq "&lt;script&gt;danger&lt;/script&gt;"
  end

  it "can use user-defined helpers from app/helpers" do
    expect(presenter.hello_world).to eq "Hello, world!"
  end

  it "can be passed to path helpers" do
    expect(helpers.post_path(presenter)).to eq "/en/posts/#{object.id}"
  end

  it "can use path helpers with its model" do
    expect(presenter.path_with_model).to eq "/en/posts/#{object.id}"
  end

  it "can use path helpers with its id" do
    expect(presenter.path_with_id).to eq "/en/posts/#{object.id}"
  end

  it "can be passed to url helpers" do
    expect(helpers.post_url(presenter)).to eq "http://www.example.com:12345/en/posts/#{object.id}"
  end

  it "can use url helpers with its model" do
    expect(presenter.url_with_model).to eq "http://www.example.com:12345/en/posts/#{object.id}"
  end

  it "can use url helpers with its id" do
    expect(presenter.url_with_id).to eq "http://www.example.com:12345/en/posts/#{object.id}"
  end

  it "can be passed implicitly to url_for" do
    expect(presenter.link).to eq "<a href=\"/en/posts/#{object.id}\">#{object.id}</a>"
  end

  it "serializes overriden attributes" do
    expect(presenter.serializable_hash["updated_at"]).to be :overridden
  end

  it "serializes to JSON" do
    json = presenter.to_json
    expect(json).to match /"updated_at":"overridden"/
  end

  it "serializes to XML" do
    pending("Rails < 3.2 does not use `serializable_hash` in `to_xml`") if Rails.version.to_f < 3.2

    xml = Capybara.string(presenter.to_xml)
    expect(xml).to have_css "post > updated-at", text: "overridden"
  end

  it "uses a test view context from ApplicationController" do
    expect(StrongPresenter::ViewContext.current.controller).to be_an ApplicationController
  end
end
