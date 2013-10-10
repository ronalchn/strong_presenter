module StrongPresenter
  class HelperProxy < ActionView::Base
    include Rails.application.routes.url_helpers

    def method_missing method, *args, &block
      if ApplicationController.helpers.respond_to? method
        ApplicationController.helpers.public_send method, *args, &block
      else
        super
      end
    end
    def respond_to? method, include_all = false
      ApplicationController.helpers.respond_to?(method, include_all) or super
    end
  end
end
