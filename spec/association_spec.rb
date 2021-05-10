require 'association'
require 'item'
require 'block'

describe Association do
  before do
    ObjectSpace.garbage_collect
    items = {
      '9' => {
        'content' => 'entity1',
        'subItemIds' => [
          10
        ],
        'entity' => true,
        'category' => 'entity'
      },
      '10' => {
        'content' => 'association1',
        'subItemIds' => [
          11
        ],
        'association' => true,
        'category' => 'association'
      },
      '11' => {
        'content' => 'entity2',
        'subItemIds' => [],
        'entity' => true,
        'category' => 'entity'
      }
    }
    @block = Block.new('9', items)
    @item = Item.new(@block)
  end

  describe '#initialize' do
    it 'is created correctly' do
      expect(Association.all[0].first_item.class).to eq(Item)
      expect(Association.all[0].name).to eq('association1')
      expect(Association.all[0].second_items.size).to eq(1)
    end
  end
  describe '.all' do
    it 'returns all created instances' do
      expect(Association.all.size).to eq(1)
    end
  end
end
