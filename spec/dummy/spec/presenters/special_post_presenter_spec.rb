require 'spec_helper'

describe SpecialPostPresenter do
  it 'has special collection' do
    expect(SpecialPostPresenter::Collection).to be SpecialPostsPresenter
  end

  it 'collection knows about presenter' do
    expect(SpecialPostsPresenter.send(:presenter_class)).to be SpecialPostPresenter
  end
end
