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

    [:action_controller, :action_mailer, :active_model_serializers].each do |klass|
      initializer "strong_presenter.setup_#{klass}" do |app|
        ActiveSupport.on_load klass do
          StrongPresenter.send "setup_#{klass}", self
        end
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
