require 'spec_helper'

module StrongPresenter
  describe Permissions do
    describe "#complete?" do
      it 'is initially incomplete' do
        expect(Permissions.new.complete?).to be false
      end
    end

    describe "#permit_all!" do
      it 'completes the object' do
        expect(Permissions.new.permit_all!.complete?).to be true
      end
    end

    describe "#permit" do
      it 'permits an attribute' do
        expect(Permissions.new.permit([], :attr).permitted?([], :attr)).to be true
      end

      it 'permits with prefix' do
        expect(Permissions.new.permit(:prefix, :attr).permitted?(:prefix, :attr)).to be true
      end

      it 'permits with arrays of symbols' do
        expect(Permissions.new.permit([:prefix, :array], [:attr, :array]).permitted?([:prefix, :array], [:attr, :array])).to be true
      end

      it 'permits multiple at once' do
        permissions = Permissions.new.permit([:prefix, :array], [:attr, :array], :attr2, :attr3)
        expect(permissions.permitted?([:prefix, :array], :attr2)).to be true
        expect(permissions.permitted?([:prefix, :array], [:attr, :array])).to be true
      end

      it 'does not mutate arguments' do
        prefix = [:pre, :fix]
        attrpaths = [[:attr, :path], :s]
        Permissions.new.permit(prefixarg = prefix.dup, attrpathsarg = attrpaths.dup)

        expect(prefixarg).to eq prefix
        expect(attrpathsarg).to eq attrpaths
      end
    end

    describe "#permitted?" do
      context 'with some attributes permitted' do
        before(:all) do
          @permissions = Permissions.new.permit([:prefix, :array], [:attr, :array], :attr2, :attr3)
        end

        it 'permits more specific paths' do
          expect(@permissions.permitted?([:prefix, :array], [:attr2, :irrelevant])).to be true
        end

        it 'does not permit un-prefixed path' do
          expect(@permissions.permitted?(:attr2)).to be false
          expect(@permissions.permitted?([:attr2, :irrelevant])).to be false
        end

        it 'permits changed prefix boundaries' do
          expect(@permissions.permitted?([:prefix, :array, :attr2], [:irrelevant])).to be true
          expect(@permissions.permitted?(:prefix, [:array, :attr2, :irrelevant])).to be true
          expect(@permissions.permitted?([:prefix], [:array, :attr2, :irrelevant])).to be true
          expect(@permissions.permitted?([], [:prefix, :array, :attr2, :irrelevant])).to be true
        end

        it 'does not permit other attributes' do
          expect(@permissions.permitted?([:prefix, :array], [:attr4, :irrelevant])).to be false
        end

        it 'does not permit shortened paths' do
          expect(@permissions.permitted?([:prefix, :array], :attr)).to be false
        end

        it 'does not mutate arguments' do
          prefix = [:pre, :fix]
          attrpaths = [[:attr, :path], :s, [:array, :attr2]]

          @permissions.permitted?(prefixarg = prefix.dup, attrpathsarg = attrpaths.dup)
          expect(prefixarg).to eq prefix
          expect(attrpathsarg).to eq attrpaths

          prefix = [:prefix]
          @permissions.permitted?(prefixarg = prefix.dup, attrpathsarg = attrpaths.dup)
          expect(prefixarg).to eq prefix
          expect(attrpathsarg).to eq attrpaths
        end
      end

      context 'with permit all' do
        it 'everything is true' do
          permissions = Permissions.new.permit_all!
          expect(permissions.permitted?(:a)).to be true
          expect(permissions.permitted?([:a])).to be true
          expect(permissions.permitted?([:a,:b])).to be true
          expect(permissions.permitted?(:a,:b)).to be true
          expect(permissions.permitted?([],:a)).to be true
          expect(permissions.permitted?([],[:a])).to be true
          expect(permissions.permitted?([:x,:y],[:a])).to be true
          expect(permissions.permitted?([],[:a,:b])).to be true
        end
      end
    end
    describe "#select_permitted" do
      context 'with some attributes permitted' do
        before(:all) do
          @permissions = Permissions.new.permit([:prefix, :array], [:attr, :array], :attr2, :attr3)
          @permissions.permit([], [:attr, :array], :attr2, :attr3)
        end

        it 'can select something which is permitted' do
          expect(@permissions.select_permitted([], :attr2)).to eq [[:attr2]]
          expect(@permissions.select_permitted([:prefix], [:array, :attr2, :irrelevant])).to eq [[:array, :attr2, :irrelevant]]
          expect(@permissions.select_permitted([:prefix, :array], [:attr2, :irrelevant])).to eq [[:attr2, :irrelevant]]
        end

        it 'can select multiple permitted attributes' do
          attribute_paths = [:attr2, :attr3, [:attr2, :irrelevant], [:attr, :array]]
          permitted = @permissions.select_permitted([:prefix, :array], *attribute_paths)
          attribute_paths.each do |attribute_path|
            expect(permitted).to include Array(attribute_path)
          end
        end

        it 'selects only permitted attributes in the original order' do
          permitted_paths = [:attr2, :attr3, [:attr2, :irrelevant], [:attr, :array], [:attr3, :ir]]
          unpermitted_paths = [:attr4, :attr5, [:attrk, :irrelevant], [:attr, :ar]]
          attribute_paths = (unpermitted_paths + permitted_paths).shuffle
          expect(@permissions.select_permitted([:prefix, :array], *attribute_paths)).to eq((attribute_paths & permitted_paths).map{|a|Array(a)})
        end

        it 'does not mutate arguments' do
          prefix = [:pre, :fix]
          attrpaths = [[:attr, :path], :s, [:array, :attr2]]

          @permissions.select_permitted(prefixarg = prefix.dup, attrpathsarg = attrpaths.dup)
          expect(prefixarg).to eq prefix
          expect(attrpathsarg).to eq attrpaths

          prefix = [:prefix]
          @permissions.select_permitted(prefixarg = prefix.dup, attrpathsarg = attrpaths.dup)
          expect(prefixarg).to eq prefix
          expect(attrpathsarg).to eq attrpaths
        end
      end

      context 'with permit all' do
        it 'everything is selected' do
          permissions = Permissions.new.permit_all!
          attribute_paths = [:attr2, :attr3, [:attr2, :irrelevant], [:attr, :array]]
          permitted = permissions.select_permitted([:prefix, :array], *attribute_paths)
          expect(permitted).to eq(attribute_paths.map{|a|Array(a)})
        end
      end
    end
    describe "#reject_permitted" do
      context 'with some attributes permitted' do
        before(:all) do
          @permissions = Permissions.new.permit([:prefix, :array], [:attr, :array], :attr2, :attr3)
          @permissions.permit([], [:attr, :array], :attr2, :attr3)
        end

        it 'selects only unpermitted attributes in the original order' do
          permitted_paths = [:attr2, :attr3, [:attr2, :irrelevant], [:attr, :array], [:attr3, :ir]]
          unpermitted_paths = [:attr4, :attr5, [:attrk, :irrelevant], [:attr, :ar]]
          attribute_paths = (unpermitted_paths + permitted_paths).shuffle
          expect(@permissions.reject_permitted([:prefix, :array], *attribute_paths)).to eq((attribute_paths & unpermitted_paths).map{|a|Array(a)})
        end

        it 'does not mutate arguments' do
          prefix = [:pre, :fix]
          attrpaths = [[:attr, :path], :s, [:array, :attr2]]

          @permissions.reject_permitted(prefixarg = prefix.dup, attrpathsarg = attrpaths.dup)
          expect(prefixarg).to eq prefix
          expect(attrpathsarg).to eq attrpaths

          prefix = [:prefix]
          @permissions.reject_permitted(prefixarg = prefix.dup, attrpathsarg = attrpaths.dup)
          expect(prefixarg).to eq prefix
          expect(attrpathsarg).to eq attrpaths
        end
      end
    end
  end
end

