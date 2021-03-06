module TestUnit
  class PresenterGenerator < ::Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def create_test_file
      template 'presenter_test.rb', File.join('test/presenters', class_path, "#{singular_name}_presenter_test.rb")
    end
  end
end
