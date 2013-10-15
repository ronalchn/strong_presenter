require 'fast_spec_helper'

require 'active_model/naming'
require_relative '../app/presenters/post_presenter'

StrongPresenter::ViewContext.test_strategy :fast

Post = Struct.new(:id) { extend ActiveModel::Naming }

describe PostPresenter do
  let(:presenter) { PostPresenter.new(object) }
  let(:object) { Post.new(42) }

  it "can use built-in helpers" do
    expect(presenter.truncated).to eq "Once upon a..."
  end

  it "can use built-in private helpers" do
    expect(presenter.html_escaped).to eq "&lt;script&gt;danger&lt;/script&gt;"
  end

  it "can't use user-defined helpers from app/helpers" do
    expect{presenter.hello_world}.to raise_error NoMethodError, /hello_world/
  end

  it "can't use path helpers" do
    expect{presenter.path_with_model}.to raise_error NoMethodError, /post_path/
  end

  it "can't use url helpers" do
    expect{presenter.url_with_model}.to raise_error NoMethodError, /post_url/
  end

  it "can't be passed implicitly to url_for" do
    expect{presenter.link}.to raise_error
  end
end
