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
        'content' => 'entity2',
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
        'content' => 'entity2',
        'subItemIds' => [],
        'entity' => true,
        'category' => 'entity'
      }
    }
    @block = Block.new('10', items)
    @item = Item.new(@block)
  end

  describe '#initialize' do
    it 'is created correctly' do
      expect(Association.all[0].first_item.class).to eq(Item)
      expect(Association.all[0].name).to eq('has_many')
      expect(Association.all[0].second_items.size).to eq(1)
    end
  end

  describe '#has_many?' do
    it "returns whether an instance's content is 'has_many'" do
      expect(Association.all[0].has_many?).to eq(true)
    end
  end

  describe '#has_one' do
    it "returns whether an instance's content is 'has_one'" do
      expect(Association.all[1].has_one?).to eq(true)
    end
  end

  describe '#has_any?' do
    it "returns whether an instance's content is 'has_many' or 'has_one'" do
      expect(Association.all[0].has_any?).to eq(true)
      expect(Association.all[1].has_any?).to eq(true)
    end
  end

  describe '#through?' do
    it "returns whether an instance's content is ':through'" do
      expect(Association.all[2].through?).to eq(true)
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Association.all.size).to eq(3)
    end
  end
end
