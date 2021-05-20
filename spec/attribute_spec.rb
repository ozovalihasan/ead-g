require 'block'
require 'item'
require 'attribute'

describe Attribute do
  before do
    ObjectSpace.garbage_collect
    items = {
      '10' => {
        'content' => 'entity1',
        'subItemIds' => [
          11, 12, 13
        ],
        'category' => 'entity'
      },
      '11' => {
        'content' => 'attribute1',
        'subItemIds' => [],
        'attribute' => true,
        'type' => 'string',
        'category' => 'attribute'
      },
      '12' => {
        'content' => 'attribute2',
        'subItemIds' => [13],
        'attribute' => true,
        'type' => 'string',
        'category' => 'attribute'
      },
      '13' => {
        'content' => 'attribute container',
        'subItemIds' => [14],
        'attributeContainer' => true,
        'category' => 'attributeContainer'
      },
      '14' => {
        'content' => 'attribute3',
        'subItemIds' => [],
        'attribute' => true,
        'type' => 'float',
        'category' => 'attribute'
      }
    }

    @block = Block.new('10', items)
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
      expect(Attribute.all.size).to eq(3)
    end
  end
end
