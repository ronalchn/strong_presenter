require 'spec_helper'
require 'support/shared_examples/view_helpers'

module StrongPresenter
  describe Presenter do
    it_behaves_like "view helpers", Presenter.new(Model.new)

    describe "#initialize" do
      it "sets the object" do
        object = Model.new
        presenter = Presenter.new(object)

        expect(presenter.send :object).to be object
      end

      it "takes a block" do
        object = Product.new
        presenter = ProductPresenter.new(object) do |presenter|
          expect(presenter.class).to be ProductPresenter
        end

        expect(presenter.class).to be ProductPresenter
      end
    end

    describe "ActiveModel compatibility" do
      protect_class(Product)

      before(:each) do
        @product_presenter = ProductPresenter.new(Product.new)
      end

      it '#to_model' do
        expect(@product_presenter.to_model).to be @product_presenter
      end

      it '#to_param' do
        Product.send(:define_method, :to_param) {123}
        expect(@product_presenter.to_param).to be 123
      end

      it '#to_partial_path' do
        Product.send(:define_method, :to_partial_path) {'/product!/'}
        expect(@product_presenter.to_partial_path).to eq '/product!/'
      end

      describe '#attributes' do
        protect_class(CarPresenter)
        before(:each) do
          car = Car.new
          car.license_plate = "IMHERE"
          @car_presenter = CarPresenter.new(car)
        end

        it 'is initially empty' do
          expect(@car_presenter.attributes).to be_empty
        end

        it 'shows associations' do
          CarPresenter.send(:define_method, :license_plate) { object.license_plate }
          expect(@car_presenter.attributes).to eq({"license_plate" => "IMHERE"})
        end
      end
    end

    describe "Unconventional name" do
      before(:each) do
        stub_const('StrangePresent', Class.new(StrongPresenter::Presenter))
      end

      it 'has no object class' do
        expect(StrangePresent.send :object_class?).to be_false
      end

      it 'raises source error' do
        expect{StrangePresent.send :object_class}.to raise_error(StrongPresenter::UninferrableSourceError)
      end

      it 'can set present' do
        StrangePresent.send(:presents, :car)
        expect(StrangePresent.send :object_class).to be Car
        presenter = StrangePresent.new(Car.new)
        expect(StrangePresent.model_name).to be Car.model_name
        expect(presenter.send(:car)).to be presenter.send(:object)
      end
    end

    describe "::presents" do
      protect_class(ProductPresenter)
      
      it 'handles inferred case' do
        ProductPresenter.send(:presents, :product)
        expect(ProductPresenter.send :object_class).to be Product
        product_presenter = ProductPresenter.new(Product.new)
        expect(product_presenter.send(:product)).to be product_presenter.send(:object)
      end
    end

    describe "::Collection" do
      it "finds corresponding collection presenter" do
        expect(ProductPresenter::Collection).to be ProductsPresenter
      end

      it "creates a new collection presenter if one does not exist" do
        expect{OthersPresenter}.to raise_error(NameError)
        expect(OtherPresenter::Collection.superclass).to be StrongPresenter::CollectionPresenter
        expect{OthersPresenter}.to raise_error(NameError)
      end

      it "sets inferred presenter on default collection presenter" do
        expect(OtherPresenter::Collection.send :presenter_class).to be OtherPresenter
      end

      it "infers presenter on collection presenter" do
        expect(ProductPresenter::Collection.send :presenter_class).to be ProductPresenter
      end

      it "uses correct collection with chained inheritance" do
        stub_const("NewProductPresenter", Class.new(ProductPresenter))

        expect(NewProductPresenter::Collection.send :presenter_class).to be NewProductPresenter
      end
    end
  end
end
