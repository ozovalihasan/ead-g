require 'item'
require 'block'
require 'active_support/core_ext/string'
require 'fileutils'

describe Item do
  before do
    ObjectSpace.garbage_collect
    items = {
      '9' => {
        'content' => 'entity1',
        'subItemIds' => [
          17,
          14,
          12,
          10
        ],
        'entity' => true,
        'category' => 'entity'
      },
      '10' => {
        'content' => 'has_many',
        'subItemIds' => [
          11,
          18
        ],
        'association' => true,
        'category' => 'association'
      },
      '11' => {
        'content' => 'entity3',
        'subItemIds' => [],
        'entity' => true,
        'category' => 'entity'
      },
      '12' => {
        'content' => 'has_one',
        'subItemIds' => [
          13
        ],
        'association' => true,
        'category' => 'association'
      },
      '13' => {
        'content' => 'entity2',
        'subItemIds' => [
          21
        ],
        'entity' => true,
        'category' => 'entity'
      },
      '14' => {
        'content' => 'attribute container',
        'subItemIds' => [
          16,
          15
        ],
        'type' => 'string',
        'attributeContainer' => true,
        'category' => 'attributeContainer'
      },
      '15' => {
        'content' => 'attribute3',
        'subItemIds' => [],
        'attribute' => true,
        'type' => 'float',
        'category' => 'attribute'
      },
      '16' => {
        'content' => 'attribute2',
        'subItemIds' => [],
        'attribute' => true,
        'type' => 'text',
        'category' => 'attribute'
      },
      '17' => {
        'content' => 'attribute1',
        'subItemIds' => [],
        'attribute' => true,
        'type' => 'string',
        'category' => 'attribute'
      },
      '18' => {
        'content' => 'entity4',
        'subItemIds' => [
          19
        ],
        'entity' => true,
        'category' => 'entity'
      },
      '19' => {
        'content' => 'belongs_to',
        'subItemIds' => [
          20
        ],
        'association' => true,
        'category' => 'association'
      },
      '20' => {
        'content' => 'entity5',
        'subItemIds' => [
          23,
          25
        ],
        'entity' => true,
        'category' => 'entity'
      },
      '21' => {
        'content' => 'has_many',
        'subItemIds' => [
          22
        ],
        'association' => true,
        'category' => 'association'
      },
      '22' => {
        'content' => 'entity6',
        'subItemIds' => [],
        'entity' => true,
        'category' => 'entity'
      },
      '23' => {
        'content' => 'has_many',
        'subItemIds' => [
          24
        ],
        'association' => true,
        'category' => 'association'
      },
      '24' => {
        'content' => 'entity7',
        'subItemIds' => [],
        'entity' => true,
        'category' => 'entity'
      },
      '25' => {
        'content' => 'attribute4',
        'subItemIds' => [],
        'attribute' => true,
        'type' => 'string',
        'category' => 'attribute'
      }
    }
    @block = Block.new('9', items)
    Item.new(@block)
    @item = Item.all.select { |item| item.name == 'entity5' }[0]
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@item.name).to eq('entity5')
      expect(@item.parent[:item].name).to eq('entity4')
      expect(@item.parent[:association].name).to eq('belongs_to')
      expect(@item.grand_parent_item.name).to eq('entity1')
      expect(@item.associations[0].name).to eq('has_many')
      expect(@item.attributes[0].name).to eq('attribute4')
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Item.all.size).to eq(7)
    end
  end

  describe '#create_migration' do
    it 'runs command to generate a model and its attributes' do
      expect_any_instance_of(Object).to receive(:system).with 'bundle exec rails generate model Entity5 attribute4:string'
      @item.create_migration
    end
  end

  describe '#add_associations_to_model' do
    it 'updates model files of Ruby on Rails project' do
      class MockFile
        attr_reader :content

        def initialize
          @content = []
        end

        def <<(para)
          @content << para
        end
      end

      mock_file = MockFile.new
      allow(File).to receive(:open).and_return(mock_file)
      allow(mock_file).to receive(:close)
      allow(File).to receive(:close)
      mock_model_file = ['class MockClass', 'end']
      allow(File).to receive(:new).and_return(mock_model_file)
      allow(mock_model_file).to receive(:close)
      allow(FileUtils).to receive(:mv)
      @item.add_associations_to_model
      expect(mock_file.content).to eq(['class MockClass', "  has_many :entity4s\n", 'end',
                                       'class MockClass', "  has_many :entity5s, through: :entity4s\n", 'end',
                                       'class MockClass', "  has_many :entity1s, through: :entity4s\n", 'end',
                                       'class MockClass', "  belongs_to :entity5\n", 'end',
                                       'class MockClass', "  has_many :entity7s\n", 'end'])
    end
  end
end
