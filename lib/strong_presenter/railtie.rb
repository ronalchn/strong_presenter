module StrongPresenter
  class Railtie < Rails::Railtie
    initializer "setup_helper_proxy" do |app|
      ActiveSupport.on_load :action_controller do
        require 'strong_presenter/helper_proxy' # a hack currently
      end
    end
  end
end
