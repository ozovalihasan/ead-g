require 'association'
require 'item'
require 'block'

describe Association do
  before do
    ObjectSpace.garbage_collect
    items = {
      '10' => {
        'content' => 'entity1',
        'subItemIds' => [
          11
        ],
        'entity' => true,
        'category' => 'entity'
      },
      '11' => {
        'content' => 'has_many',
        'subItemIds' => [
          12
        ],
        'association' => true,
        'category' => 'association'
      },
      '12' => {
        'content' => 'entity2',
        'subItemIds' => [
          13
        ],
        'entity' => true,
        'category' => 'entity'
      },
      '13' => {
        'content' => 'has_one',
        'subItemIds' => [
          14
        ],
        'association' => true,
        'category' => 'association'
      },
      '14' => {
        'content' => 'entity3',
        'subItemIds' => [
          15
        ],
        'entity' => true,
        'category' => 'entity'
      },
      '15' => {
        'content' => ':through',
        'subItemIds' => [
          16
        ],
        'association' => true,
        'category' => 'association'
      },
      '16' => {
        'content' => 'entity4',
        'subItemIds' => [],
        'entity' => true,
        'category' => 'entity'
      }
    }
    @block = Block.new('10', items)
    @item1 = Item.new(@block)
    @association1 = @item1.associations.first
    @item2 = @association1.second_items.first
    @association2 = @item2.associations.first
    @item3 = @association2.second_items.first
    @association3 = @item3.associations.first
  end

  describe '#initialize' do
    it 'is created correctly' do
      expect(@association1.first_item.class).to eq(Item)
      expect(@association1.name).to eq('has_many')
      expect(@association1.second_items.size).to eq(1)
    end
  end

  describe '#has_many?' do
    it "returns whether an instance's name is 'has_many'" do
      expect(@association1.has_many?).to eq(true)
    end
  end

  describe '#add_second_items?' do
    it 'adds items to second_items of association' do
      expect(@association1.second_items.size).to eq(1)
      @association1.add_second_items(@block.sub_blocks.first)
      expect(@association1.second_items.size).to eq(2)
    end
  end

  describe '#has_one?' do
    it "returns whether an instance's name is 'has_one'" do
      expect(@association2.has_one?).to eq(true)
    end
  end

  describe '#has_any?' do
    it "returns whether an instance's name is 'has_many' or 'has_one'" do
      expect(@association1.has_any?).to eq(true)
      expect(@association2.has_any?).to eq(true)
    end
  end

  describe '#through?' do
    it "returns whether an instance's name is ':through'" do
      expect(@association3.through?).to eq(true)
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Association.all.size).to eq(3)
    end
  end
end
