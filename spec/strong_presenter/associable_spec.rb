require 'spec_helper'

module StrongPresenter
  describe Associable do
    context 'with Presenter' do
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

      it 'does not allow presenting without permit!' do
        expect(@product_presenter.presents :manufacturer).to be_empty
        expect(@product_presenter.presents [:manufacturer, :name]).to be_empty
        @product_presenter.permit! :name
        expect(@product_presenter.presents [:manufacturer, :name]).to be_empty
      end

      it 'does not allow presenting from association' do
        expect(@product_presenter.manufacturer.presents :name).to be_empty
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

    context 'with CollectionPresenter' do
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
  end
end

