module StrongPresenter
  class Railtie < Rails::Railtie

    config.after_initialize do |app|
      app.config.paths.add 'app/presenters', eager_load: true

      if Rails.env.test?
        require 'strong_presenter/test_case'
        require 'strong_presenter/test/rspec_integration' if defined?(RSpec) and RSpec.respond_to?(:configure)
        require 'strong_presenter/test/minitest_integration' if defined?(MiniTest::Rails)
      end
    end

    initializer "strong_presenter.setup_action_controller" do |app|
      ActiveSupport.on_load :action_controller do
        StrongPresenter.setup_action_controller self
      end
    end

    initializer "strong_presenter.setup_action_mailer" do |app|
      ActiveSupport.on_load :action_mailer do
        StrongPresenter.setup_action_mailer self
      end
    end

    initializer "strong_presenter.setup_active_model_serializers" do |app|
      ActiveSupport.on_load :active_model_serializers do
        StrongPresenter::CollectionPresenter.send :include, ActiveModel::ArraySerializerSupport
      end
    end

    console do
      require 'action_controller/test_case'
      ApplicationController.new.view_context
      StrongPresenter::ViewContext.build
    end

## No rake tasks
#    rake_tasks do
#      Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
#    end

  end
end
