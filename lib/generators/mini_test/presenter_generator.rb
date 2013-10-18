require 'generators/mini_test'

module MiniTest
  module Generators
    class PresenterGenerator < Base
      def self.source_root
        File.expand_path('../templates', __FILE__)
      end

      class_option :spec, :type => :boolean, :default => false, :desc => "Use MiniTest::Spec DSL"

      check_class_collision suffix: "PresenterTest"

      def create_test_file
        template_type = options[:spec] ? "spec" : "test"
        template "presenter_#{template_type}.rb", File.join("test/presenters", class_path, "#{singular_name}_presenter_test.rb")
      end
    end
  end
end
