require 'block'

describe Block do
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
        'subItemIds' => [],
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
        'subItemIds' => [],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'entityAssociation' => true,
        'expand' => true,
        'category' => 'entityAssociation',
        'factory' => false,
        'isDropDisabled' => false
      }
    }
    Block.new('9', items)
    @block = Block.find('10')
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@block.id).to eq('10')
      expect(@block.content).to eq('entity container')
      expect(@block.category).to eq('entityContainer')
      expect(@block.attribute).to eq(nil)
      expect(@block.entity).to eq(nil)
      expect(@block.entity_container).to eq(true)
      expect(@block.type).to eq(nil)
      expect(@block.association).to eq(nil)
      expect(@block.entity_clone).to eq(nil)
      expect(@block.cloneable).to eq(nil)
      expect(@block.clone_blocks).to eq(nil)
      expect(@block.clone_parent).to eq('')
      expect(@block.sub_blocks.size).to eq(0)
      expect(Block.find('9').sub_blocks.size).to eq(2)
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Block.all.size).to eq(3)
    end
  end

  describe '.find' do
    it 'finds a block with its id' do
      expect(Block.find('10').content).to eq('entity container')
    end
  end
end
