require 'ead'
require 'active_support/core_ext/string'

describe EAD do
  before do
    ObjectSpace.garbage_collect
    @items = {
      '8' => {
        'content' => 'EAD',
        'subItemIds' => [
          9
        ],
        'category' => 'EAD'
      },
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
    @items = @items.to_json
    @ead = EAD.new
  end

  describe '.import_JSON' do
    it 'imports JSON file and creates blocks by using imported data' do
      allow(File).to receive(:read).and_return(@items)
      @ead.import_JSON([])
      expect(Block.all.size).to eq(4)
    end

    it 'imports JSON file with custom path and creates blocks by using imported data' do
      allow(File).to receive(:read).with('custom.json').and_return(@items)
      @ead.import_JSON(['custom.json'])
      expect(Block.all.size).to eq(4)
    end
  end

  describe '.check_implement_items' do
    it 'checks block having EAD content and create models and associations' do
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
      call_add_associations_to_model = 0
      allow_any_instance_of(Item).to receive(:add_associations_to_model) { |_arg| call_add_associations_to_model += 1 }

      @ead.import_JSON([])
      @ead.check_implement_items
      expect(Item.all.size).to eq(2)
      expect(Association.all.size).to eq(1)
      expect(call_create_migration).to eq(2)
      expect(call_add_associations_to_model).to eq(2)
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
