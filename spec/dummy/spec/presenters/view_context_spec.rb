require 'spec_helper'

def it_does_not_leak_view_context
  2.times do
    it "has an independent view context" do
      expect(StrongPresenter::ViewContext.current).not_to be :leaked
      StrongPresenter::ViewContext.current = :leaked
    end
  end
end

describe "A presenter spec", type: :presenter do
  it_does_not_leak_view_context
end

describe "A controller spec", type: :controller do
  it_does_not_leak_view_context
end

describe "A mailer spec", type: :mailer do
  it_does_not_leak_view_context
end
