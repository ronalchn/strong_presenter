require 'minitest_helper'

def it_is_a_presenter_test
  it "is a presenter test" do
    assert_kind_of StrongPresenter::TestCase, self
  end
end

def it_is_not_a_presenter_test
  it "is not a presenter test" do
    refute_kind_of StrongPresenter::TestCase, self
  end
end

ProductPresenter = Class.new(StrongPresenter::Presenter)
ProductsPresenter = Class.new(StrongPresenter::CollectionPresenter)

describe ProductPresenter do
  it_is_a_presenter_test
end

describe ProductsPresenter do
  it_is_a_presenter_test
end

describe "ProductPresenter" do
  it_is_a_presenter_test
end

describe "AnyPresenter" do
  it_is_a_presenter_test
end

describe "Any presenter" do
  it_is_a_presenter_test
end

describe "AnyPresenterTest" do
  it_is_a_presenter_test
end

describe "Any presenter test" do
  it_is_a_presenter_test
end

describe Object do
  it_is_not_a_presenter_test
end

describe "Nope" do
  it_is_not_a_presenter_test
end
