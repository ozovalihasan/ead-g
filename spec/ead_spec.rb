require 'ead'
require 'active_support/core_ext/string'

describe EAD do
  before do
    ObjectSpace.garbage_collect
    @file = {
      'version' => '0.3.1',
      'items' => {
        '0' => {
          'content' => 'Initialize your project from EAD',
          'subItemIds' => [
            1,
            9
          ],
          'order' => 'vertical',
          'subdirection' => 'row',
          'isDropDisabled' => true,
          'isDragDisabled' => true,
          'expand' => true
        },
        '1' => {
          'content' => 'Elements',
          'subItemIds' => [
            2,
            3,
            4,
            5,
            6,
            7,
            8
          ],
          'order' => 'vertical',
          'subdirection' => 'column',
          'isDropDisabled' => true,
          'isDragDisabled' => true,
          'expand' => true,
          'factory' => true,
          'category' => 'factory'
        },
        '2' => {
          'content' => 'has_many',
          'subItemIds' => [],
          'order' => 'horizontal',
          'subdirection' => 'row',
          'isDropDisabled' => true,
          'factory' => true,
          'association' => true,
          'expand' => true,
          'category' => 'association'
        },
        '3' => {
          'content' => 'has_one',
          'subItemIds' => [],
          'order' => 'horizontal',
          'subdirection' => 'row',
          'isDropDisabled' => true,
          'factory' => true,
          'association' => true,
          'expand' => true,
          'category' => 'association'
        },
        '4' => {
          'content' => ' =>through',
          'subItemIds' => [],
          'order' => 'horizontal',
          'subdirection' => 'row',
          'isDropDisabled' => true,
          'factory' => true,
          'association' => true,
          'expand' => true,
          'category' => 'association'
        },
        '5' => {
          'content' => 'entities & associations',
          'subItemIds' => [],
          'order' => 'horizontal',
          'subdirection' => 'row',
          'isDropDisabled' => true,
          'factory' => true,
          'type' => 'string',
          'expand' => true,
          'entityAssociation' => true,
          'category' => 'entityAssociation'
        },
        '6' => {
          'content' => 'attribute',
          'subItemIds' => [],
          'attribute' => true,
          'order' => 'vertical',
          'subdirection' => 'column',
          'isDropDisabled' => true,
          'factory' => true,
          'type' => 'string',
          'expand' => true,
          'category' => 'attribute'
        },
        '7' => {
          'content' => 'entity',
          'subItemIds' => [],
          'order' => 'vertical',
          'subdirection' => 'column',
          'factory' => true,
          'entity' => true,
          'expand' => true,
          'isDropDisabled' => true,
          'category' => 'entity',
          'cloneable' => true,
          'cloneChildren' => []
        },
        '8' => {
          'content' => 'entity container',
          'subItemIds' => [],
          'order' => 'vertical',
          'subdirection' => 'column',
          'factory' => true,
          'entityContainer' => true,
          'expand' => true,
          'isDropDisabled' => true,
          'category' => 'entityContainer'
        },
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
          'subItemIds' => [
            16,
            12
          ],
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
          'subItemIds' => [
            13
          ],
          'order' => 'horizontal',
          'subdirection' => 'row',
          'entityAssociation' => true,
          'expand' => true,
          'category' => 'entityAssociation',
          'factory' => false,
          'isDropDisabled' => false
        },
        '12' => {
          'content' => 'entity1',
          'subItemIds' => [],
          'order' => 'vertical',
          'subdirection' => 'column',
          'factory' => false,
          'entity' => true,
          'expand' => true,
          'isDropDisabled' => false,
          'category' => 'entity',
          'cloneable' => true,
          'cloneChildren' => [
            13
          ]
        },
        '13' => {
          'content' => 'entity1',
          'subItemIds' => [
            14
          ],
          'order' => 'horizontal',
          'subdirection' => 'row',
          'factory' => false,
          'expand' => true,
          'isDropDisabled' => false,
          'category' => 'entityClone',
          'entityClone' => true,
          'cloneParent' => 12,
          'parentId' => 11,
          'parentIndex' => 0
        },
        '14' => {
          'content' => 'has_many',
          'subItemIds' => [
            17
          ],
          'order' => 'horizontal',
          'subdirection' => 'row',
          'isDropDisabled' => false,
          'factory' => false,
          'association' => true,
          'expand' => true,
          'category' => 'association'
        },
        '16' => {
          'content' => 'entity2',
          'subItemIds' => [],
          'order' => 'vertical',
          'subdirection' => 'column',
          'factory' => false,
          'entity' => true,
          'expand' => true,
          'isDropDisabled' => false,
          'category' => 'entity',
          'cloneable' => true,
          'cloneChildren' => [
            17
          ]
        },
        '17' => {
          'content' => 'entity2',
          'subItemIds' => [],
          'order' => 'horizontal',
          'subdirection' => 'row',
          'factory' => false,
          'expand' => true,
          'isDropDisabled' => false,
          'category' => 'entityClone',
          'entityClone' => true,
          'cloneParent' => 16,
          'parentId' => 14,
          'parentIndex' => 0
        }
      }
    }
    @file = @file.to_json
    @ead = EAD.new
  end

  describe '.import_JSON' do
    it 'imports JSON file and creates blocks by using imported data' do
      allow(File).to receive(:read).and_return(@file)
      @ead.import_JSON([])
      expect(Block.all.size).to eq(8)
    end

    it 'imports JSON file with custom path and creates blocks by using imported data' do
      allow(File).to receive(:read).with('custom.json').and_return(@file)
      @ead.import_JSON(['custom.json'])
      expect(Block.all.size).to eq(8)
    end
  end

  describe '#create_items' do
    it 'creates all necessary instances of Item and ItemClone' do
      allow(File).to receive(:read).and_return(@file)
      @ead.import_JSON([])
      ead_id = '9'
      block = Block.find(ead_id)
      @ead.create_items(block)
      expect(Item.all.size).to eq(2)
      expect(ItemClone.all.size).to eq(2)
    end
  end

  describe '.check_implement_items' do
    it 'checks block having EAD content and create models and associations' do
      require 'item'
      allow(File).to receive(:read).and_return(@file)
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
      allow_any_instance_of(ItemClone).to receive(:add_associations) { |_arg| call_add_associations += 1 }

      @ead.import_JSON([])
      @ead.check_implement_items

      expect(Item.all.size).to eq(2)
      expect(Association.all.size).to eq(1)
      expect(call_create_migration).to eq(2)
      expect(call_add_associations).to eq(2)
    end
  end

  describe '.check_latest_version' do
    context 'if there is an internet connection' do
      it 'checks the latest version of the gem and prints a warning about new release of the gem' do
        response = RestClient::Response.new [{name: ''}].to_json

        allow(RestClient::Request).to receive(:execute).and_return(response)
        
        expect { @ead.check_latest_version }.to output(
          "\n\n----------------"\
          "\n\n"\
          "\e[33m"\
          "A new version of this gem has been released."\
          " Please check it. https://github.com/ozovalihasan/ead-g/releases"\
          "\e[0m"\
          "\n\n----------------\n\n"
        ).to_stdout
      end
    end

    context "if there isn't an internet connection" do
      it 'prints a warning about unstable internet connection' do
        response = StandardError

        allow(RestClient::Request).to receive(:execute).and_return(response)

        expect { @ead.check_latest_version }.to output(
          "\n\n----------------"\
          "\n\n"\
          "\e[31m"\
          "If you want to check the latest version of this gem,"\
          " you need to have a stable internet connection."\
          "\e[0m"\
           "\n\n----------------\n\n"
        ).to_stdout
      end
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
