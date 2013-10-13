require 'test_helper'

def it_does_not_leak_view_context
  2.times do |n|
    define_method("test_has_independent_view_context_#{n}") do
      #refute_equal :leaked, StrongPresenter::ViewContext.current
      #StrongPresenter::ViewContext.current = :leaked
    end
  end
end

class PresenterTest < StrongPresenter::TestCase
  #it_does_not_leak_view_context
end

class ControllerTest < ActionController::TestCase
  tests Class.new(ActionController::Base)

  #it_does_not_leak_view_context
end

class MailerTest < ActionMailer::TestCase
  #it_does_not_leak_view_context
end
