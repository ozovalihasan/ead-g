require 'block'

describe Block do
  before do
    ObjectSpace.garbage_collect
    items = {
      '9' => {
        'content' => 'entity1',
        'subItemIds' => [
          10
        ],
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
        'category' => 'entity'
      }
    }
    @block = Block.new('9', items)
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@block.id).to eq('9')
      expect(@block.content).to eq('entity1')
      expect(@block.category).to eq('entity')
      expect(@block.attribute_container).to eq(nil)
      expect(@block.attribute).to eq(nil)
      expect(@block.type).to eq(nil)
      expect(@block.association).to eq(nil)
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
      expect(Block.find('9').content).to eq('entity1')
    end
  end
end
