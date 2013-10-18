require 'spec_helper'

module StrongPresenter
  describe Delegation do
    protect_class(Product)
    protect_class(ProductPresenter)

    it '#delegate to object by default' do
      ProductPresenter.delegate :stuff
      Product.send(:define_method, :stuff) {"stuffed"}
      expect(ProductPresenter.new(Product.new).stuff).to eq "stuffed"
    end

    it 'can #delegate elsewhere' do
      ProductPresenter.send(:define_method, :elsewhere) {[3,4,5]}
      ProductPresenter.delegate :array, :to => :elsewhere
      expect(ProductPresenter.new(Product.new).elsewhere.size).to eq 3
    end
  end
end
