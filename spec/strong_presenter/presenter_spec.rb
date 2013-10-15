require 'spec_helper'

module StrongPresenter
  describe Presenter do
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

    describe "Collection" do
      it "finds corresponding collection presenter" do
        expect(ProductPresenter::Collection).to be ProductsPresenter
      end

      it "creates a new collection presenter if one does not exist" do
        expect{OthersPresenter}.to raise_error(NameError)
        expect(OtherPresenter::Collection.superclass).to be StrongPresenter::CollectionPresenter
        expect{OthersPresenter}.to raise_error(NameError)
      end

      it "sets inferred presenter on default collection presenter" do
        expect{OtherPresenter::Collection.inferred_presenter_class}.to raise_error NoMethodError
        expect(OtherPresenter::Collection.send :presenter_class).to be OtherPresenter
      end

      it "infers presenter on collection presenter" do
        expect{ProductPresenter::Collection.inferred_presenter_class}.to raise_error NoMethodError
        expect(ProductPresenter::Collection.send :inferred_presenter_class).to be ProductPresenter
      end
    end

    describe "Permissible" do
      it "filters permitted attributes" do
        object = Model.new
        presenter = Presenter.new(object)
        
        presenter.permit :a, :b, :c
        permitted = presenter.filter :a, :c, :z
        expect(permitted).to include(:a, :c)
        expect(permitted).to_not include(:b, :z)
      end

      it "permits all if permit!" do
        object = Model.new
        presenter = Presenter.new(object)

        presenter.permit!
        permitted = presenter.filter :a, :b, :c
        expect(permitted).to include(:a, :b, :c)
      end
    end
    
    context 'with presented association' do
      protect_class Product
      protect_class ProductPresenter

      before(:each) do
        class Manufacturer < Model
          def name; "Factory"; end
        end
        class ManufacturerPresenter < StrongPresenter::Presenter
          def name(*args); "Presented #{object.name}#{(args+[""])[0]}"; end
        end
        Product.send(:define_method, :manufacturer) { @manufacturer ||= Manufacturer.new }
        Product.send(:define_method, :name) { "Product" }
        ProductPresenter.presents_association :manufacturer

        @product_presenter = ProductPresenter.new(Product.new)
      end

      it 'presents association' do
        expect(@product_presenter.manufacturer.class).to be ManufacturerPresenter
        expect(@product_presenter.manufacturer.name).to eq "Presented Factory"
      end

      it 'does not allow presenting without permit' do
        expect(@product_presenter.presents :manufacturer).to be_empty
        expect(@product_presenter.presents [:manufacturer, :name]).to be_empty
        @product_presenter.permit :name
        expect(@product_presenter.presents [:manufacturer, :name]).to be_empty
      end

      it 'does not allow presenting from association' do
        expect(@product_presenter.manufacturer.presents :name).to be_empty
      end

      context 'with association permitted' do
        before(:each) do
          @product_presenter.permit :manufacturer
        end

        it 'allows presenting association' do
          expect(@product_presenter.present(:manufacturer).class).to be ManufacturerPresenter
        end

        it 'allows presenting association attributes' do
          expect(@product_presenter.present [:manufacturer, :name]).to eq "Presented Factory"
        end

        it 'allows presenting association attributes with arguments' do
          expect(@product_presenter.present [:manufacturer, :name, " arg"]).to eq "Presented Factory arg"
        end

        it 'allows presenting from association' do
          expect(@product_presenter.manufacturer.present :name).to eq "Presented Factory"
        end
      end

      it 'rejects full path from association' do
        @product_presenter.permit [:manufacturer, :name]
        expect(@product_presenter.manufacturer.presents [:manufacturer, :name]).to be_empty
      end
    end
    context 'with association to collection' do
      protect_class Product
      protect_class ProductPresenter
      before(:each) do
        Product.send(:define_method, :initialize) { |name| @name = name }
        Product.send(:attr_reader, :name)
        ProductPresenter.send(:define_method, :name) { object.name }
        class ProductList < Model
          attr_accessor :products
          def initialize; @products = [Product.new("X"), Product.new("Y"), Product.new("Z")]; end
        end
        class ProductListPresenter < StrongPresenter::Presenter
          presents_associations :products
        end

        @presenter = ProductListPresenter.new(ProductList.new)
      end

      it 'presents collection' do
        expect(@presenter.products).to be_a StrongPresenter::CollectionPresenter
      end

      it 'allows accessing collection elements' do
        expect(@presenter.products[2].class).to be ProductPresenter
        expect(@presenter.products[2].name).to eq "Z"
      end
    end
  end
end
