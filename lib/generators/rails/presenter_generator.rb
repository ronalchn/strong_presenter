module Rails
  module Generators
   class PresenterGenerator < NamedBase
      source_root File.expand_path("../templates", __FILE__)
      check_class_collision suffix: "Presenter"

      class_option :parent, type: :string, desc: "The parent class for the generated presenter"

      def create_presenter_file
        template 'presenter.rb', File.join('app/presenters', class_path, "#{file_name}_presenter.rb")
      end

      hook_for :test_framework

      private

      def parent_class_name
        options.fetch("parent") do
          begin
            require 'application_presenter'
            ApplicationPresenter
          rescue LoadError
            "StrongPresenter::Presenter"
          end
        end
      end

      # Rails 3.0.X compatibility, stolen from https://github.com/jnunemaker/mongomapper/pull/385/files#L1R32
      unless methods.include?(:module_namespacing)
        def module_namespacing
          yield if block_given?
        end
      end
    end
  end
end
