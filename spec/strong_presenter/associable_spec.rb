require 'spec_helper'

module StrongPresenter
  describe Associable do
    context 'with Presenter' do
      protect_class Product
      protect_class ProductPresenter

      before(:each) do
        stub_const('Manufacturer', Class.new(Model))
        Manufacturer.send(:define_method, :name) {"Factory"}
        stub_const('ManufacturerPresenter', Class.new(StrongPresenter::Presenter))
        ManufacturerPresenter.send(:define_method, :name) { |*args| "Presented #{object.name}#{(args+[""])[0]}" }
        Product.send(:define_method, :manufacturer) { @manufacturer ||= Manufacturer.new }
        Product.send(:define_method, :name) { "Product" }
        ProductPresenter.presents_association :manufacturer
        ManufacturerPresenter.presents_association :source
        Manufacturer.send(:define_method, :source) { @manufacturer ||= Manufacturer.new }

        @product_presenter = ProductPresenter.new(Product.new)
      end

      it 'presents association' do
        expect(@product_presenter.manufacturer.class).to be ManufacturerPresenter
        expect(@product_presenter.manufacturer.name).to eq "Presented Factory"
      end

      it 'does not allow presenting without permit!' do
        expect(@product_presenter.presents :manufacturer).to be_empty
        expect(@product_presenter.presents [:manufacturer, :name]).to be_empty
        @product_presenter.permit! :name
        expect(@product_presenter.presents [:manufacturer, :name]).to be_empty
      end

      it 'does not allow presenting from association' do
        expect(@product_presenter.manufacturer.presents :name).to be_empty
      end

      it 'presents nested assocations' do
        @product_presenter.permit! :**
        expect(@product_presenter.present [:manufacturer, :source, :name]).to eq "Presented Factory"
      end

      context 'with association methods permitted' do
        before(:each) do
          @product_presenter.permit! [:manufacturer, :*]
        end

        it 'allows presenting association if exact match' do
          expect(@product_presenter.present(:manufacturer)).to be_nil
          @product_presenter.permit! :manufacturer
          expect(@product_presenter.present(:manufacturer).class).to be ManufacturerPresenter
        end

        it 'allows presenting association methods' do
          expect(@product_presenter.present [:manufacturer, :name]).to eq "Presented Factory"
        end

        it 'cannot present method with arguments' do
          expect(@product_presenter.present [:manufacturer, :name, " arg"]).to be_nil
        end

        it 'allows presenting from association' do
          expect(@product_presenter.manufacturer.present :name).to eq "Presented Factory"
        end
      end

      it 'rejects full path from association' do
        @product_presenter.permit! [:manufacturer, :name]
        expect(@product_presenter.manufacturer.presents [:manufacturer, :name]).to be_empty
      end
    end

    context 'with missing constants' do
      protect_class Product
      protect_class ProductPresenter

      it 'can declare association without ActiveRecord' do
        hide_const('ActiveRecord')
        Product.send(:define_method, :inverse) { @inverse ||= Product.new }
        ProductPresenter.presents_association :inverse
        @product_presenter = ProductPresenter.new(Product.new)
        expect(@product_presenter.inverse.class).to be ProductPresenter
      end

      it 'can declare association with empty ActiveRecord' do
        stub_const('ActiveRecord', Module.new)
        Product.send(:define_method, :inverse) { @inverse ||= Product.new }
        ProductPresenter.presents_association :inverse
        @product_presenter = ProductPresenter.new(Product.new)
        expect(@product_presenter.inverse.class).to be ProductPresenter
      end
    end

    context 'with CollectionPresenter' do
      protect_class Product
      protect_class ProductPresenter
      before(:each) do
        stub_const('ProductList', Class.new(Model))
        Product.send(:define_method, :initialize) { |name| @name = name }
        Product.send(:attr_reader, :name)
        ProductPresenter.send(:define_method, :name) { object.name }
        class ProductList
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

    describe "with ActiveRecord::Base objects" do
      protect_class WheelPresenter
      protect_class CarPresenter
      it 'infers collection presenter from association class' do
        CarPresenter.presents_association :wheels

        car = Car.new
        car.wheels << Wheel.new
        presenter = CarPresenter.new(car)
        expect(presenter.wheels.class).to be WheelPresenter::Collection
      end

      it 'cannot infer without presenter' do
        hide_const('WheelPresenter')
        CarPresenter.presents_association :wheels

        car = Car.new
        car.wheels << Wheel.new
        presenter = CarPresenter.new(car)
        expect(presenter.wheels.class).to be StrongPresenter::CollectionPresenter
        expect{presenter.wheels[0]}.to raise_error StrongPresenter::UninferrablePresenterError
      end

      it 'infers collection presenter on factory construction' do
        hide_const('WheelPresenter')
        stub_const('WheelsPresenter', Class.new(StrongPresenter::CollectionPresenter))
        WheelsPresenter.send(:define_method, :number_of){object.size}
        CarPresenter.presents_association :wheels

        car = Car.new
        car.wheels = [Wheel.new, Wheel.new, Wheel.new]
        presenter = CarPresenter.new(car)
        expect(presenter.wheels.class).to be WheelsPresenter
        expect(presenter.wheels.number_of).to be 3
      end

      it 'infers presenter of polymorphic association' do
        WheelPresenter.presents_association :vehicle

        wheel = Wheel.new
        wheel.vehicle = Car.new
        presenter = WheelPresenter.new(wheel)
        expect(presenter.vehicle.class).to be CarPresenter
      end

      it 'infers new association after reload' do
        WheelPresenter.presents_association :vehicle
        wheel = Wheel.new
        wheel.vehicle = Car.new
        presenter = WheelPresenter.new(wheel)
        presenter.vehicle
        wheel.vehicle = Wheel.new
        expect(presenter.vehicle.class).to be CarPresenter
        expect(presenter.reload!.vehicle.class).to be WheelPresenter
        expect(presenter.vehicle.class).to be WheelPresenter
      end
    end

    describe 'without suitable presenter' do
      protect_class Product
      it 'throws uninferrable presenter' do
        Product.send(:attr_accessor, :string)
        ProductPresenter.presents_association :string
        Product.send(:define_method, :initialize) { self.string = "String"}
        
        presenter = ProductPresenter.new(Product.new)
        expect{presenter.string}.to raise_error(StrongPresenter::UninferrablePresenterError)
      end
    end

    describe 'Permissible' do
      protect_class Product
      protect_class ProductPresenter
      before (:each) do
        Product.send(:attr_accessor, :name, :description, :price, :subproducts, :other)
        Product.send(:define_method, :initialize) do |name, description = "Description", price = 1, subproducts = []|
          self.name = name
          self.description = description
          self.price = price
          self.subproducts = Array(subproducts)
          self.other = Wheel.new
        end
        ProductPresenter.presents_association :subproducts
        ProductPresenter.presents_association :other
        ProductPresenter.delegate :name, :description, :price
        @product = Product.new("Main", "I, Main", 4.2, [Product.new("Sub A", "Small", 8), Product.new("Component B")])
        @product_presenter = ProductPresenter.new(@product)
      end

      it 'collection association inherits permissions' do
        @product_presenter.permit! [:subproducts, :name]
        expect(@product_presenter.subproducts.select_permitted(:name, :price)).to eq [:name]
      end

      it 'association inherits permissions' do
        @product_presenter.permit! [:other, :stuff]
        expect(@product_presenter.other.select_permitted(:other, :stuff)).to eq [:stuff]
      end

      it 'collection item inherits permissions' do
        @product_presenter.permit! [:subproducts, :name]
        expect(@product_presenter.subproducts[0].presents(:name, :price)).to eq ["Sub A"]
      end

      it 'forwards permit to associations' do
        other_presenter = @product_presenter.other
        @product_presenter.permit! [:other, :stuff]
        expect(other_presenter.select_permitted(:other, :stuff)).to eq [:stuff]
      end

      it 'forwards permit to association collection items' do
        subproduct_presenter = @product_presenter.subproducts[0]
        @product_presenter.permit! [:subproducts, :name]
        expect(subproduct_presenter.presents(:name, :price)).to eq ["Sub A"]
      end

      it 'does not feed permissions to siblings' do
        @product_presenter.subproducts[0].permit! :name
        expect(@product_presenter.subproducts[0].presents(:name, :price)).to eq ["Sub A"]
        expect(@product_presenter.subproducts[1].presents(:name, :price)).to be_empty
      end

      it 'appears to clear permissions on reload' do
        @product_presenter.subproducts[0].permit! :name
        expect(@product_presenter.reload!.subproducts[0].presents(:name, :price)).to be_empty
      end

      it 'can add to association permissions' do
        @product_presenter.permit! [:subproducts, :name]
        @product_presenter.subproducts[0].permit! :price
        expect(@product_presenter.subproducts[0].presents(:name, :price)).to eq ["Sub A", 8]
      end

      it 'can add to collection permissions' do
        @product_presenter.permit! [:subproducts, :name]
        @product_presenter.subproducts.permit! :description
        expect(@product_presenter.subproducts[0].presents(:name, :price, :description)).to eq ["Sub A", "Small"]
      end

      it 'can add to item permissions' do
        @product_presenter.subproducts.permit! :description
        @product_presenter.subproducts[0].permit! :price
        expect(@product_presenter.subproducts[0].presents(:name, :price, :description)).to eq [8, "Small"]
        expect(@product_presenter.subproducts[1].presents(:name, :price, :description)).to eq ["Description"]
      end

      it 'adds propagated permissions' do
        @product_presenter.subproducts[0].permit! :price
        @product_presenter.permit! [:subproducts, :name]
        expect(@product_presenter.subproducts[0].presents(:name, :price, :description)).to eq ["Sub A", 8]
      end

      it 'propagates double wildcard' do
        @product_presenter.subproducts[0].permit! :price
        @product_presenter.permit! :**
        expect(@product_presenter.subproducts[0].presents(:name, "price", :description)).to eq ["Sub A", 8, "Small"]
      end

      it 'does not propagate single wildcard' do
        @product_presenter.subproducts[0].permit! :price
        @product_presenter.permit! :*
        expect(@product_presenter.subproducts[0].presents(:name, :price, :description)).to eq [8]
      end

      it 'can propagate string path to collection' do
        @product_presenter.subproducts.permit! :price
        @product_presenter.permit! ["subproducts", "name"]
        expect(@product_presenter.subproducts[0].presents(:name, :price, :description)).to eq ["Sub A", 8]
      end

      it 'propagates wildcard ending' do
        @product_presenter.subproducts[0].permit! :price
        @product_presenter.permit! [:subproducts, :*]
        expect(@product_presenter.subproducts[0].presents(:name, "price", :description)).to eq ["Sub A", 8, "Small"]
      end

      it 'handles taint with mixture of wildcard and exact matches' do
        @product_presenter.subproducts[0].permit! :price
        @product_presenter.permit! [:subproducts, :*]
        expect(@product_presenter.subproducts[0].presents(:name, "price".taint, "description".taint)).to eq ["Sub A", 8]
      end
    end
  end
end

