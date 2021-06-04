require 'association'
require 'item_clone'
require 'block'

describe Association do
  before do
    ObjectSpace.garbage_collect
    items = {
      '9' => {
        'content' => 'EAD',
        'subItemIds' => [
          10,
          11
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'isDragDisabled' => true,
        'expand' => true,
        'category' => 'EAD'
      },
      '10' => {
        'content' => 'entity container',
        'subItemIds' => [
          16,
          15,
          14,
          13
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'entityContainer' => true,
        'expand' => true,
        'category' => 'entityContainer',
        'factory' => false,
        'isDropDisabled' => false
      },
      '11' => {
        'content' => 'entities & associations',
        'subItemIds' => [
          17
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'entityAssociation' => true,
        'expand' => true,
        'category' => 'entityAssociation',
        'factory' => false,
        'isDropDisabled' => false
      },
      '13' => {
        'content' => 'entity1',
        'subItemIds' => [],
        'order' => 'vertical',
        'subdirection' => 'column',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entity',
        'cloneable' => true,
        'cloneChildren' => [
          17
        ]
      },
      '14' => {
        'content' => 'entity2',
        'subItemIds' => [],
        'order' => 'vertical',
        'subdirection' => 'column',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entity',
        'cloneable' => true,
        'cloneChildren' => [
          19
        ]
      },
      '15' => {
        'content' => 'entity3',
        'subItemIds' => [],
        'order' => 'vertical',
        'subdirection' => 'column',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entity',
        'cloneable' => true,
        'cloneChildren' => [
          21
        ]
      },
      '16' => {
        'content' => 'entity4',
        'subItemIds' => [],
        'order' => 'vertical',
        'subdirection' => 'column',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entity',
        'cloneable' => true,
        'cloneChildren' => [
          23
        ]
      },
      '17' => {
        'content' => 'entity1',
        'subItemIds' => [
          18
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entityClone',
        'entityClone' => true,
        'cloneParent' => 13,
        'parentId' => 11,
        'parentIndex' => 0
      },
      '18' => {
        'content' => 'has_many',
        'subItemIds' => [
          19
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'isDropDisabled' => false,
        'factory' => false,
        'association' => true,
        'expand' => true,
        'category' => 'association'
      },
      '19' => {
        'content' => 'entity2',
        'subItemIds' => [
          20
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entityClone',
        'entityClone' => true,
        'cloneParent' => 14,
        'parentId' => 18,
        'parentIndex' => 0
      },
      '20' => {
        'content' => 'has_one',
        'subItemIds' => [
          21
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'isDropDisabled' => false,
        'factory' => false,
        'association' => true,
        'expand' => true,
        'category' => 'association'
      },
      '21' => {
        'content' => 'entity3',
        'subItemIds' => [
          22
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entityClone',
        'entityClone' => true,
        'cloneParent' => 15,
        'parentId' => 20,
        'parentIndex' => 0
      },
      '22' => {
        'content' => ':through',
        'subItemIds' => [
          23
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'isDropDisabled' => false,
        'factory' => false,
        'association' => true,
        'expand' => true,
        'category' => 'association'
      },
      '23' => {
        'content' => 'entity4',
        'subItemIds' => [],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entityClone',
        'entityClone' => true,
        'cloneParent' => 16,
        'parentId' => 22,
        'parentIndex' => 0
      }
    }

    Block.new('9', items)
    @block = Block.find('17')
    @item1 = ItemClone.new(Block.find('17'))
    @association1 = @item1.associations.first
    @item2 = @association1.second_items.first
    @association2 = @item2.associations.first
    @item3 = @association2.second_items.first
    @association3 = @item3.associations.first
  end

  describe '#initialize' do
    it 'is created correctly' do
      expect(@association1.first_item.class).to eq(ItemClone)
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
