require 'spec_helper'

module StrongPresenter
  describe Permissible do
    it "selects permitted attributes" do
      object = Model.new
      presenter = Presenter.new(object)
      
      presenter.permit! :a, :b, :c
      permitted = presenter.select_permitted :a, :c, :z
      expect(permitted).to include(:a, :c)
      expect(permitted).to_not include(:b, :z)
    end

    it "permits all if permit_all!" do
      object = Model.new
      presenter = Presenter.new(object)

      presenter.permit_all!
      permitted = presenter.select_permitted :a, :b, :c
      expect(permitted).to include(:a, :b, :c)
    end
  end
end
