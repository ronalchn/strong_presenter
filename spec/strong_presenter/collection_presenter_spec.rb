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
    describe "Permissible" do
      it "permits on items" do
        collection = [Model.new, Model.new]
        collection_presenter = CollectionPresenter.new(collection, :with => Presenter)

        expect(collection_presenter[0].filter :z).to be_empty

        collection_presenter.permit :a, :b, :c
        permitted = collection_presenter[0].filter :a, :c, :z
        expect(permitted).to include(:a, :c)
        expect(permitted).to_not include(:b, :z)
      end
    end
  end
end
