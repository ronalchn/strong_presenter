require 'spec_helper'

module StrongPresenter
  describe CollectionPresenter do
    describe "#initialize" do
      it "sets the collection" do
        collection = [Model.new, Model.new]
        collection_presenter = CollectionPresenter.new(collection, :with => Presenter)

        expect(collection_presenter.send :object).to be collection
        expect(collection_presenter[0].send :object).to be collection[0]
      end
      it "wraps with given presenter" do
        collection = [Product.new, Product.new]
        products_presenter = CollectionPresenter.new(collection, :with => ProductPresenter)

        expect(products_presenter[0].class).to be ProductPresenter
      end
    end

    it "has to_s method" do
      collection = CollectionPresenter.new([Model.new, Model.new])
      expect(collection.to_s).to include "inferred"
    end

    describe "Permissible" do
      before(:each) do
        @collection = [Model.new, Model.new]
        @collection_presenter = CollectionPresenter.new(@collection, :with => Presenter)
      end

      it "collection permits on items" do
        expect(@collection_presenter[0].select_permitted :z).to be_empty

        @collection_presenter.permit! :a, :b, :c
        permitted = @collection_presenter[0].select_permitted :a, :c, :z
        expect(permitted).to include(:a, :c)
        expect(permitted).to_not include(:b, :z)
      end

      it "permits items" do
        @collection_presenter[0].permit! :a
        expect(@collection_presenter[0].select_permitted :a).to eq [:a]
      end

      it "does not leak item permit to siblings" do
        @collection_presenter[0].permit! :a
        expect(@collection_presenter[1].select_permitted :a).to be_empty
      end

      it "resets item permit on reload" do
        @collection_presenter[0].permit! :a
        @collection_presenter.reload!
        expect(@collection_presenter[0].select_permitted :a).to be_empty
      end

      it "propagates to items" do
        @collection_presenter[0].permit! :a
        expect(@collection_presenter[0].select_permitted :a, :b).to eq [:a]
        @collection_presenter.permit! :b
        expect(@collection_presenter[0].select_permitted :a, :b).to eq [:a, :b]
        expect(@collection_presenter[1].select_permitted :a, :b).to eq [:b]
      end
    end
  end
end
