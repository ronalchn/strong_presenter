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
        expect(OtherPresenter::Collection.send :presenter_class).to be OtherPresenter
      end

      it "infers presenter on collection presenter" do
        expect(ProductPresenter::Collection.send :presenter_class).to be ProductPresenter
      end
    end
  end
end
