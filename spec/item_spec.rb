require 'item'
require 'block'
require 'active_support/core_ext/string'
require 'fileutils'

describe Item do
  before do
    ObjectSpace.garbage_collect
    items = {
      '9' => {
        'content' => 'Physician',
        'subItemIds' => [
          29,
          27,
          10
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'color' => '#94F6EA',
        'category' => 'entity'
      },
      '10' => {
        'content' => 'has_many',
        'subItemIds' => [
          11
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'association' => true,
        'expand' => true,
        'color' => '#C7FDED',
        'category' => 'association'
      },
      '11' => {
        'content' => 'Appointment',
        'subItemIds' => [
          12
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'color' => '#94F6EA',
        'category' => 'entity'
      },
      '12' => {
        'content' => ':through',
        'subItemIds' => [
          13
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'association' => true,
        'expand' => true,
        'color' => '#C7FDED',
        'category' => 'association'
      },
      '13' => {
        'content' => 'Patient',
        'subItemIds' => [],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'color' => '#94F6EA',
        'category' => 'entity'
      },
      '14' => {
        'content' => 'Supplier',
        'subItemIds' => [
          17
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'entity' => true,
        'expand' => false,
        'isDropDisabled' => false,
        'color' => '#94F6EA',
        'category' => 'entity'
      },
      '17' => {
        'content' => 'has_one',
        'subItemIds' => [
          18
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'association' => true,
        'expand' => true,
        'color' => '#C7FDED',
        'category' => 'association'
      },
      '18' => {
        'content' => 'Account',
        'subItemIds' => [
          22
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'color' => '#94F6EA',
        'category' => 'entity'
      },
      '19' => {
        'content' => 'Author',
        'subItemIds' => [
          25,
          20
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'entity' => true,
        'expand' => false,
        'isDropDisabled' => false,
        'color' => '#94F6EA',
        'category' => 'entity'
      },
      '20' => {
        'content' => 'has_many',
        'subItemIds' => [
          21
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'association' => true,
        'expand' => true,
        'color' => '#C7FDED',
        'category' => 'association'
      },
      '21' => {
        'content' => 'Books',
        'subItemIds' => [],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'color' => '#94F6EA',
        'category' => 'entity'
      },
      '22' => {
        'content' => ':through',
        'subItemIds' => [
          23
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'association' => true,
        'expand' => true,
        'color' => '#C7FDED',
        'category' => 'association'
      },
      '23' => {
        'content' => 'AccountHistory',
        'subItemIds' => [],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'factory' => false,
        'entity' => true,
        'expand' => true,
        'isDropDisabled' => false,
        'color' => '#94F6EA',
        'category' => 'entity'
      },
      '24' => {
        'content' => 'password',
        'subItemIds' => [],
        'attribute' => true,
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'type' => 'string',
        'expand' => true,
        'color' => '#AAFAE9',
        'category' => 'attribute'
      },
      '25' => {
        'content' => 'attribute container',
        'subItemIds' => [
          26,
          24
        ],
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'type' => 'string',
        'expand' => true,
        'attributeContainer' => true,
        'color' => '#AAFAE9',
        'category' => 'attributeContainer'
      },
      '26' => {
        'content' => 'attribute',
        'subItemIds' => [],
        'attribute' => true,
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'type' => 'string',
        'expand' => true,
        'color' => '#AAFAE9',
        'category' => 'attribute'
      },
      '27' => {
        'content' => 'attribute container',
        'subItemIds' => [
          28
        ],
        'order' => 'horizontal',
        'subdirection' => 'row',
        'isDropDisabled' => false,
        'factory' => false,
        'type' => 'string',
        'expand' => true,
        'attributeContainer' => true,
        'color' => '#AAFAE9',
        'category' => 'attributeContainer'
      },
      '28' => {
        'content' => 'salary',
        'subItemIds' => [],
        'attribute' => true,
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'type' => 'integer',
        'expand' => true,
        'color' => '#AAFAE9',
        'category' => 'attribute'
      },
      '29' => {
        'content' => 'name',
        'subItemIds' => [],
        'attribute' => true,
        'order' => 'vertical',
        'subdirection' => 'column',
        'isDropDisabled' => false,
        'factory' => false,
        'type' => 'string',
        'expand' => true,
        'color' => '#AAFAE9',
        'category' => 'attribute'
      }
    }
    @block = Block.new('9', items)
    Item.new(@block)
    @appointment = Item.all.select { |item| item.name == 'appointment' }[0]
    @patient = Item.all.select { |item| item.name == 'patient' }[0]
    @physician = Item.all.select { |item| item.name == 'physician' }[0]
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@appointment.name).to eq('appointment')
      expect(@appointment.parent[:item].name).to eq('physician')
      expect(@appointment.parent[:association].name).to eq('has_many')
      expect(@patient.grand_parent[:item].name).to eq('physician')
      expect(@appointment.associations[0].name).to eq(':through')
      expect(@appointment.parent[:item].attributes[0].name).to eq('name')
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Item.all.size).to eq(3)
    end
  end

  describe '#create_migration' do
    it 'runs command to generate a model and its attributes' do
      allow_any_instance_of(Object).to receive(:system) do |_, call_with|
        expect([
                 'bundle exec rails generate model Patient',
                 'bundle exec rails generate model Appointment physician:references patient:references'
               ]).to include call_with
      end
      @appointment.create_migration
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
      @patient.add_associations_to_model

      expect(mock_file.content).to eq([
                                        'class MockClass', "  has_many :appointments\n",
                                        'end',
                                        'class MockClass',
                                        "  has_many :patients, through: :appointments\n",
                                        'end',
                                        'class MockClass',
                                        "  has_many :physicians, through: :appointments\n",
                                        'end'
                                      ])
      @physician.add_associations_to_model
      expect(mock_file.content).to eq([
                                        'class MockClass', "  has_many :appointments\n",
                                        'end',
                                        'class MockClass',
                                        "  has_many :patients, through: :appointments\n",
                                        'end',
                                        'class MockClass',
                                        "  has_many :physicians, through: :appointments\n",
                                        'end',
                                        'class MockClass',
                                        "  has_many :appointments\n",
                                        'end'
                                      ])
    end
  end
end
