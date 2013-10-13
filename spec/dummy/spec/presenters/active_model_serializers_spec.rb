require 'spec_helper'

describe StrongPresenter::CollectionPresenter do
  describe "#active_model_serializer" do
    it "returns ActiveModel::ArraySerializer" do
      collection_presenter = StrongPresenter::CollectionPresenter.new([])

      expect(collection_presenter.active_model_serializer).to be ActiveModel::ArraySerializer
    end
  end
end
