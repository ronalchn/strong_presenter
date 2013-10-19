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
        expect(Permissions.new.permit(:attr).permitted?(:attr)).to be true
      end

      it 'permits with arrays of symbols' do
        expect(Permissions.new.permit([:attr, :array]).permitted?([:attr, :array])).to be true
      end

      it 'permits multiple at once' do
        permissions = Permissions.new.permit([:another, :array], [:attr, :array], :attr2, :attr3)
        expect(permissions.permitted?(:attr2)).to be true
        expect(permissions.permitted?([:attr, :array])).to be true
      end

      it 'does not mutate arguments' do
        attrpaths = [[:attr, :path], :s]
        Permissions.new.permit(attrpathsarg = attrpaths.dup)

        expect(attrpathsarg).to eq attrpaths
      end
    end

    describe "#permitted?" do
      context 'with some attributes permitted' do
        before(:all) do
          @permissions = Permissions.new.permit([:another, :array], [:attr, :array], :attr2, :attr3, [:a, :wildcard, :*], [:wild, :**])
        end

        it 'permits single wildcard' do
          expect(@permissions.permitted?([:a, :wildcard, :irrelevant])).to be true
        end

        it 'permits full wildcard' do
          expect(@permissions.permitted?([:wild, :wildcard, :irrelevant])).to be true
          expect(@permissions.permitted?([:wild, :irrelevant])).to be true
        end

        it 'does not permit un-prefixed path' do
          permissions = Permissions.new(@permissions, :attr)
          expect(permissions.permitted?(:attr2)).to be false
          expect(permissions.permitted?([:wild, :irrelevant])).to be false
        end

        it 'permits with prefix' do
          permissions = Permissions.new(@permissions, :attr)
          expect(permissions.permitted?(:array)).to be true
        end

        it 'does not permit other attributes' do
          expect(@permissions.permitted?([:attr4, :irrelevant])).to be false
        end

        it 'does not permit shortened paths' do
          expect(@permissions.permitted?(:attr)).to be false
        end

        it 'does not mutate arguments' do
          attrpaths = [[:attr, :path], :s, [:array, :attr2]]

          @permissions.permitted?(attrpathsarg = attrpaths.dup)
          expect(attrpathsarg).to eq attrpaths

          prefix = [:prefix]
          @permissions.permitted?(attrpathsarg = attrpaths.dup)
          expect(attrpathsarg).to eq attrpaths
        end

        it 'is indifferent to strings' do
          expect(@permissions.permitted?(["attr","array"])).to be true
          expect(@permissions.permitted?("a/wildcard/irrelevant".split("/"))).to be true
        end

        it 'does not permit single wildcard if tainted' do
          expect(@permissions.permitted?([:a, :wildcard, "irrelevant".taint])).to be false
        end

        it 'does not permit full wildcard if tainted' do
          expect(@permissions.permitted?(["wild".taint, :wildcard, :irrelevant])).to be false
          expect(@permissions.permitted?(["wild", "irrelevant"].taint)).to be false
          expect(@permissions.permitted?("a/wildcard/irrelevant".taint.split("/"))).to be false
        end
      end

      context 'with permit all' do
        it 'all methods are true' do
          permissions = Permissions.new.permit_all!
          expect(permissions.permitted?(:a)).to be true
          expect(permissions.permitted?(:b)).to be true
        end

        it 'association methods are false' do
          permissions = Permissions.new.permit_all!
          expect(permissions.permitted?([:a,:a])).to be false
        end
      end
    end
    describe "#select_permitted" do
      context 'with some attributes permitted' do
        before(:all) do
          @permissions = Permissions.new.permit([:another, :array], [:attr, :array, :*], :attr2, :attr3)
          @permissions.permit([], [:attr, :arrays], :attr2, :attr3)
        end

        it 'can select something which is permitted' do
          expect(@permissions.select_permitted(:attr2)).to eq [:attr2]
          expect(@permissions.select_permitted([:attr, :array, :irrelevant])).to eq [[:attr, :array, :irrelevant]]
          expect(@permissions.select_permitted([:another, :array])).to eq [[:another, :array]]
        end

        it 'does not select wildcard path without wildcard' do
          expect(@permissions.select_permitted([:attr, :array])).to be_empty
        end

        it 'can select multiple permitted attributes' do
          attribute_paths = [[:attr2], :attr3, [:another, :array], [:attr, :array, :method]]
          permitted = @permissions.select_permitted(*attribute_paths)
          attribute_paths.each do |attribute_path|
            expect(permitted).to include attribute_path
          end
        end

        it 'selects only permitted attributes in the original order' do
          permitted_paths = [:attr2, :attr3, [:attr, :arrays], [:attr, :array, :meth], [:attr3]]
          unpermitted_paths = [:attr4, :attr5, [:attrk, :irrelevant], [:attr, :ar], [:attr, :arrays, :more]]
          attribute_paths = (unpermitted_paths + permitted_paths).shuffle
          expect(@permissions.select_permitted(*attribute_paths)).to eq((attribute_paths & permitted_paths))
        end

        it 'does not mutate arguments' do
          attrpaths = [[:attr, :path], :s, [:array, :attr2]]

          @permissions.select_permitted(attrpathsarg = attrpaths.dup)
          expect(attrpathsarg).to eq attrpaths

          attrpaths = [[:attr, :array, :meth], :s, [:array, :attr2]]
          @permissions.select_permitted(attrpathsarg = attrpaths.dup)
          expect(attrpathsarg).to eq attrpaths
        end
      end

      context 'with permit all' do
        it 'everything is selected' do
          permissions = Permissions.new.permit_all!
          attribute_paths = [:attr2, :attr3, :attr2, :attr, :array]
          permitted = permissions.select_permitted([:prefix, :array], *attribute_paths)
          expect(permitted).to eq(attribute_paths)
        end
      end
    end
    describe "#reject_permitted" do
      context 'with some attributes permitted' do
        before(:all) do
          @permissions = Permissions.new.permit([:another, :array], [:attr, :array, :*], :attr2, :attr3)
          @permissions.permit([], [:attr, :arrays], :attr2, :attr3)
        end

        it 'selects only unpermitted attributes in the original order' do
          permitted_paths = [:attr2, :attr3, [:attr, :arrays], [:attr, :array, :meth], [:attr3]]
          unpermitted_paths = [:attr4, :attr5, [:attrk, :irrelevant], [:attr, :ar], [:attr, :arrays, :more]]
          attribute_paths = (unpermitted_paths + permitted_paths).shuffle
          expect(@permissions.reject_permitted(*attribute_paths)).to eq((attribute_paths & unpermitted_paths))
        end

        it 'does not mutate arguments' do
          attrpaths = [[:attr, :path], :s, [:array, :attr2]]

          @permissions.reject_permitted(attrpathsarg = attrpaths.dup)
          expect(attrpathsarg).to eq attrpaths

          attrpaths = [[:attr, :array, :meth], :s, [:array, :attr2]]
          @permissions.reject_permitted(attrpathsarg = attrpaths.dup)
          expect(attrpathsarg).to eq attrpaths
        end
      end
    end
  end
end

