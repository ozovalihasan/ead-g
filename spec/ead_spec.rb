require 'ead'
require 'active_support/core_ext/string'

describe EAD do
  before do
    ObjectSpace.garbage_collect
    @file = JSON.parse(File.read("#{__dir__}/ead_spec_sample.json"))
    @file = @file.to_json
    @ead = EAD.new
  end

  describe '.import_JSON' do
    it 'imports JSON file' do
      allow(File).to receive(:read).and_return(@file)
      file = @ead.import_JSON([])
      expect(file).to eq(@file)
    end

    it 'imports JSON file with a custom path' do
      allow(File).to receive(:read).with('custom.json').and_return(@file)
      file = @ead.import_JSON(['custom.json'])
      expect(file).to eq(@file)
    end
  end

  describe '#create_items' do
    it 'creates all necessary instances of Item and ItemClone' do
      allow(File).to receive(:read).and_return(@file)
      file = @ead.import_JSON([])
      @ead.create_items(file)
      expect(Item.all.size).to eq(2)
      expect(ItemClone.all.size).to eq(2)
    end
  end

  describe '.check_implement_items' do
    it 'creates all necessary instances of classes and create models and associations' do
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

      call_create_model = 0
      allow_any_instance_of(Item).to receive(:create_model) { |_arg| call_create_model += 1 }
      call_add_associations = 0
      allow_any_instance_of(ItemClone).to receive(:add_associations) { |_arg| call_add_associations += 1 }

      file = @ead.import_JSON([])
      @ead.check_implement_items(file)

      expect(Item.all.size).to eq(2)
      expect(Association.all.size).to eq(1)
      expect(call_create_model).to eq(2)
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
