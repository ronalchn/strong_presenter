require 'spec_helper'

module StrongPresenter
  describe ControllerAdditions do
    before(:each) do
      stub_const "MyController", Class.new {
        attr_writer :action_name
        def action_name
          @action_name || ""
        end
      }
      allow(MyController).to receive(:helper_method)
      allow(MyController).to receive(:before_filter)
      StrongPresenter.setup_action_controller(MyController)
    end

    describe '#presents' do
      it 'sets up arbitrary helper method for presenter' do
        expect(MyController).to receive(:helper_method).with(:arbitrary).once
        MyController.presents :arbitrary
      end

      it 'sets up multiple helper methods' do
        expect(MyController).to receive(:helper_method).with(:arbitrary).once
        expect(MyController).to receive(:helper_method).with(:arb).once
        MyController.presents :arbitrary, :arb
      end

      it 'sets up helper method with only' do
        MyController.presents :arbitrary, :only => :show
      end

      it 'sets up helper method with except' do
        MyController.presents :arbitrary, :except => :show
      end

      it 'sets up helper method with presenter option' do
        MyController.presents :arbitrary, :with => ProductPresenter
      end
    end

    context 'with product helper' do
      before(:each) do
        @controller = MyController.new
        @controller.send :instance_variable_set, :@product, Product.new
      end

      context 'with plain presents' do
        before(:each) do
          MyController.presents :product
        end

        it 'presents product' do
          expect(@controller.product.class).to be ProductPresenter
        end

        it 'memoizes presenter' do
          presenter = @controller.product
          expect(@controller.product).to be presenter
        end
      end

      context 'with only' do
        before(:each) do
          MyController.presents :product, :only => :show
        end

        it 'presents on action' do
          @controller.action_name = "show"
          expect(@controller.product.class).to be ProductPresenter
        end

        it 'does not present on action' do
          expect{@controller.product}.to raise_error NoMethodError
        end
      end

      context 'with shadowed method, multiple presents with' do
        before(:each) do
          stub_const('Presenter1', Class.new(StrongPresenter::Presenter))
          stub_const('Presenter2', Class.new(StrongPresenter::Presenter))
          MyController.send(:define_method, :product) {|number| "Product ##{number}"}
          MyController.presents :product, :with => Presenter1, :only => :unused
          MyController.presents :product, :except => :index
          MyController.presents :product, :with => Presenter1, :only => :show
          MyController.presents :product, :with => Presenter2, :only => :edit
        end

        it 'presents show on show' do
          @controller.action_name = "show"
          expect(@controller.product.class).to be Presenter1
        end

        it 'presents show on edit' do
          @controller.action_name = "edit"
          expect(@controller.product.class).to be Presenter2
        end

        it 'presents default on other' do
          expect(@controller.product.class).to be ProductPresenter
        end

        it 'presents default on shadowed unused presents' do
          @controller.action_name = "unused"
          expect(@controller.product.class).to be ProductPresenter
        end

        it 'falls back to original method without match' do
          @controller.action_name = "index"
          expect(@controller.product(5)).to eq "Product #5"
        end
      end
    end
  end
end
