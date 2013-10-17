require 'spec_helper'

module StrongPresenter
  describe Permissible do
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
end
