require 'spec_helper'
require 'rails'
require 'ammeter/init'
require 'generators/rails/presenter_generator'

describe Rails::Generators::PresenterGenerator do
  destination File.expand_path("../tmp", __FILE__)

  before { prepare_destination }
  after(:all) { FileUtils.rm_rf destination_root }

  describe "the generated presenter" do
    subject { file("app/presenters/your_model_presenter.rb") }

    describe "naming" do
      before { run_generator %w(YourModel) }

      it { should contain "class YourModelPresenter" }
    end

    describe "namespacing" do
      subject { file("app/presenters/namespace/your_model_presenter.rb") }
      before { run_generator %w(Namespace::YourModel) }

      it { should contain "class Namespace::YourModelPresenter" }
    end

    describe "inheritance" do
      context "by default" do
        before { run_generator %w(YourModel) }

        it { should contain "class YourModelPresenter < StrongPresenter::Presenter" }
      end

      context "with the --parent option" do
        before { run_generator %w(YourModel --parent=FooPresenter) }

        it { should contain "class YourModelPresenter < FooPresenter" }
      end

      context "with an ApplicationPresenter" do
        before do
          Object.any_instance.stub(:require).with("application_presenter").and_return do
            stub_const "ApplicationPresenter", Class.new
          end
        end

        before { run_generator %w(YourModel) }

        it { should contain "class YourModelPresenter < ApplicationPresenter" }
      end
    end
  end

  context "with -t=rspec" do
    describe "the generated spec" do
      subject { file("spec/presenters/your_model_presenter_spec.rb") }

      describe "naming" do
        before { run_generator %w(YourModel -t=rspec) }

        it { should contain "describe YourModelPresenter" }
      end

      describe "namespacing" do
        subject { file("spec/presenters/namespace/your_model_presenter_spec.rb") }
        before { run_generator %w(Namespace::YourModel -t=rspec) }

        it { should contain "describe Namespace::YourModelPresenter" }
      end
    end
  end

  context "with -t=test_unit" do
    describe "the generated test" do
      subject { file("test/presenters/your_model_presenter_test.rb") }

      describe "naming" do
        before { run_generator %w(YourModel -t=test_unit) }

        it { should contain "class YourModelPresenterTest < StrongPresenter::TestCase" }
      end

      describe "namespacing" do
        subject { file("test/presenters/namespace/your_model_presenter_test.rb") }
        before { run_generator %w(Namespace::YourModel -t=test_unit) }

        it { should contain "class Namespace::YourModelPresenterTest < StrongPresenter::TestCase" }
      end
    end
  end

  context "with -t=mini_test" do
    describe "the generated test" do
      subject { file("test/presenters/your_model_presenter_test.rb") }

      describe "naming" do
        before { run_generator %w(YourModel -t=mini_test) }

        it { should contain "class YourModelPresenterTest < StrongPresenter::TestCase" }
      end

      describe "namespacing" do
        subject { file("test/presenters/namespace/your_model_presenter_test.rb") }
        before { run_generator %w(Namespace::YourModel -t=mini_test) }

        it { should contain "class Namespace::YourModelPresenterTest < StrongPresenter::TestCase" }
      end
    end
  end

  context "with -t=mini_test --spec" do
    describe "the generated test" do
      subject { file("test/presenters/your_model_presenter_test.rb") }

      describe "naming" do
        before { run_generator %w(YourModel -t=mini_test --spec) }

        it { should contain "describe YourModelPresenter" }
      end

      describe "namespacing" do
        subject { file("test/presenters/namespace/your_model_presenter_test.rb") }
        before { run_generator %w(Namespace::YourModel -t=mini_test --spec) }

        it { should contain "describe Namespace::YourModelPresenter" }
      end
    end
  end

end
