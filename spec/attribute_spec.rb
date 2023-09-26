require 'table'
require 'attribute'

describe Attribute do
  before do
    require 'attribute'
    ObjectSpace.garbage_collect

    ead_file = {
      'tables' => {
        '15' => {
          'name' => 'entity1',
          'attributes' => {
            '16' => {
              'name' => 'attribute1',
              'type' => 'string'
            },
            '17' => {
              'name' => 'attribute2',
              'type' => 'string'
            },
            '18' => {
              'name' => 'attributeThree',
              'type' => 'string'
            }
          },
          'superclassId' => ''
        }
      }
    }

    @table = Table.new('15', ead_file['tables']['15'])
    @attribute = Attribute.all.select { |att| att.name == 'attribute1' }[0]
    @attribute3 = Attribute.all.select { |att| att.name == 'attribute_three' }[0]
  end

  describe '#initialize' do
    it 'creates an instance of class correctly' do
      expect(@attribute.name).to eq('attribute1')
      expect(@attribute.type).to eq('string')
      
      expect(@attribute3.name).to eq('attribute_three')
      expect(@attribute3.type).to eq('string')
    end
  end

  describe '#add_to' do
    it 'adds attribute name and type to command' do
      command = ''
      @attribute.add_to(command)
      
      expect(command).to eq(' attribute1:string')

      command = ''
      @attribute3.add_to(command)
      
      expect(command).to eq(' attribute_three:string')
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Attribute.all.size).to eq(3)
    end
  end
end
