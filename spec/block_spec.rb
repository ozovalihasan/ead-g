require 'block'

describe Block do
  before do
    ObjectSpace.garbage_collect
    items = {
      '10' => {
        'content' => 'entity1',
        'subItemIds' => [
          11
        ],
        'category' => 'entity',
        'entity' => true
      },
      '11' => {
        'content' => 'association1',
        'subItemIds' => [
          12
        ],
        'association' => true,
        'category' => 'association'
      },
      '12' => {
        'content' => 'entity2',
        'subItemIds' => [],
        'category' => 'entity'
      }
    }
    @block = Block.new('10', items)
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@block.id).to eq('10')
      expect(@block.content).to eq('entity1')
      expect(@block.category).to eq('entity')
      expect(@block.attribute_container).to eq(nil)
      expect(@block.attribute).to eq(nil)
      expect(@block.entity).to eq(true)
      expect(@block.entity_container).to eq(nil)
      expect(@block.type).to eq(nil)
      expect(@block.association).to eq(nil)
      expect(@block.entity_clone).to eq(nil)
      expect(@block.cloneable).to eq(nil)
      expect(@block.clone_blocks).to eq(nil)
      expect(@block.clone_parent).to eq('')
      expect(@block.sub_blocks.size).to eq(1)
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Block.all.size).to eq(3)
    end
  end

  describe '.find' do
    it 'finds a block with its id' do
      expect(Block.find('10').content).to eq('entity1')
    end
  end
end
