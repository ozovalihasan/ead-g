require 'block'
require 'item'
require 'attribute'

describe Attribute do
  before do
    ObjectSpace.garbage_collect
    items = {
      '12' => {
        'content' => 'entity1',
        'subItemIds' => [
          14,
          13
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'category' => 'entity',
        'cloneable' => true,
        'cloneChildren' => []
      },
      '13' => {
        'content' => 'attribute2',
        'subItemIds' => [],
        'attribute' => true,
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'type' => 'text',
        'expand' => true,
        'category' => 'attribute'
      },
      '14' => {
        'content' => 'attribute1',
        'subItemIds' => [],
        'attribute' => true,
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'type' => 'string',
        'expand' => true,
        'category' => 'attribute'
      }
    }

    @block = Block.new('12', items)
    @item = Item.new(@block)
    @attribute = Attribute.all.select { |att| att.name == 'attribute1' }[0]
  end

  describe '#initialize' do
    it 'creates an instance of class correctly' do
      expect(@attribute.name).to eq('attribute1')
      expect(@attribute.type).to eq('string')
    end
  end

  describe '#add_to' do
    it 'adds attribute name and type to command' do
      command = ''
      @attribute.add_to(command)
      expect(command).to eq(' attribute1:string')
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Attribute.all.size).to eq(2)
    end
  end
end
