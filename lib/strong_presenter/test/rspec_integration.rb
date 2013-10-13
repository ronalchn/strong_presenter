module StrongPresenter
  module PresenterExampleGroup
    include StrongPresenter::TestCase::Behavior
    extend ActiveSupport::Concern

    included { metadata[:type] = :presenter }
  end

  RSpec.configure do |config|
    config.include PresenterExampleGroup, example_group: {file_path: %r{spec/presenters}}, type: :presenter

    [:presenter, :controller, :mailer].each do |type|
      config.before(:each, type: type) { StrongPresenter::ViewContext.clear! }
    end
  end
end
