require 'ead'
require 'active_support/core_ext/string'

describe EAD do
  before do
    ObjectSpace.garbage_collect
    @items = {
      '9' => {
        'content' => 'EAD',
        'subItemIds' => [
          10
        ],
        'category' => 'EAD'
      },
      '10' => {
        'content' => 'entity1',
        'subItemIds' => [
          11
        ],
        'entity' => true,
        'category' => 'entity',
        'cloneable' => true,
        'cloneChildren' => []
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
        'content' => 'entity container',
        'subItemIds' => [13, 14],
        'entityContainer' => true,
        'category' => 'entityContainer'
      },
      '13' => {
        'content' => 'entity2',
        'subItemIds' => [],
        'entity' => true,
        'category' => 'entity',
        'cloneChildren' => [
          14
        ],
        'cloneable' => true
      },
      '14' => {
        'content' => 'entityClone1',
        'subItemIds' => [],
        'category' => 'entityClone',
        'entityClone' => true,
        'cloneParent' => 13
      }
    }
    @items = @items.to_json
    @ead = EAD.new
  end

  describe '.import_JSON' do
    it 'imports JSON file and creates blocks by using imported data' do
      allow(File).to receive(:read).and_return(@items)
      @ead.import_JSON([])
      expect(Block.all.size).to eq(6)
    end

    it 'imports JSON file with custom path and creates blocks by using imported data' do
      allow(File).to receive(:read).with('custom.json').and_return(@items)
      @ead.import_JSON(['custom.json'])
      expect(Block.all.size).to eq(6)
    end
  end

  describe '#create_items' do
    it 'creates all necessary instances of Item and ItemClone' do
      allow(File).to receive(:read).and_return(@items)
      @ead.import_JSON([])
      ead_id = '9'
      block = Block.find(ead_id)
      @ead.create_items(block)
      expect(Item.all.size).to eq(2)
      expect(ItemClone.all.size).to eq(1)
    end
  end

  describe '.check_implement_items' do
    it 'checks block having EAD content and create models and associations' do
      require 'item'
      allow(File).to receive(:read).and_return(@items)
      mock_file = ''
      allow(File).to receive(:open).and_return(mock_file)
      allow(mock_file).to receive(:close)
      allow(File).to receive(:close)
      mock_model_file = ['class MockClass', 'end']
      allow(File).to receive(:new).and_return(mock_model_file)
      allow(mock_model_file).to receive(:close)
      allow(FileUtils).to receive(:mv)

      call_create_migration = 0
      allow_any_instance_of(Item).to receive(:create_migration) { |_arg| call_create_migration += 1 }
      call_add_associations = 0
      allow_any_instance_of(Item).to receive(:add_associations) { |_arg| call_add_associations += 1 }

      @ead.import_JSON([])
      @ead.check_implement_items

      expect(Item.all.size).to eq(2)
      expect(Association.all.size).to eq(1)
      expect(call_create_migration).to eq(2)
      expect(call_add_associations).to eq(2)
    end
  end

  describe '.start' do
    it 'starts all process' do
      call_import_JSON = 0
      allow_any_instance_of(EAD).to receive(:import_JSON) { |_arg| call_import_JSON += 1 }

      call_check_implement_items = 0
      allow_any_instance_of(EAD).to receive(:check_implement_items) { |_arg| call_check_implement_items += 1 }

      @ead.start([])

      expect(call_import_JSON).to eq(1)
      expect(call_check_implement_items).to eq(1)
    end
  end
end
