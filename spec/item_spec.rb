require 'item'
require 'item_clone'
require 'block'
require 'active_support/core_ext/string'
require 'ead'

describe Item do
  before do
    ObjectSpace.garbage_collect
    @ead = EAD.new
    @ead.import_JSON(['./spec/sample_EAD.json'])
    ead_id = '9'
    block = Block.find(ead_id)
    @ead.create_items(block)

    ItemClone.all.each do |item_clone|
      parent = Item.find(item_clone.clone_parent)
      item_clone.clone_parent = Item.find(item_clone.clone_parent)
      parent.clones << item_clone
    end

    @account_history = Item.all.select { |item| item.name == 'account_history' }[0]
    @picture = Item.all.select { |item| item.name == 'picture' }[0]
    @user = Item.all.select { |item| item.name == 'user' }[0]
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@account_history.id).to eq('23')
      expect(@account_history.name).to eq('account_history')
      expect(@account_history.attributes[0].name).to eq('credit_rating')
      expect(@account_history.clones.size).to eq(1)
      expect(@account_history.polymorphic).to eq(false)
      expect(@account_history.polymorphic_names).to eq([])
    end
  end

  describe '#add_to_attributes' do
    it 'adds an attribute to attributes of item' do
      expect(@account_history.attributes.size).to eq(2)

      block = Block.find('49')
      @account_history.add_to_attributes(block)

      expect(@account_history.attributes.size).to eq(3)
    end
  end

  describe '#model_name' do
    it 'returns camelized name ' do
      expect(@account_history.model_name).to eq('AccountHistory')
    end
  end

  describe '#add_references' do
    it 'adds references to command' do
      command = ''
      @account_history.add_references(command, @account_history.clones.first.parent)
      expect(command).to eq(' account:references')
    end
  end

  describe '#add_polymorphic' do
    it 'adds polymorphic reference to command' do
      command = ''
      @account_history.add_polymorphic(command, 'mock_polymorphic_name')
      expect(command).to eq(' mock_polymorphic_name:references{polymorphic}')
    end
  end

  describe '#update_polymorphic_names' do
    it 'adds polymorphic reference to command' do
      @picture.update_polymorphic_names
      expect(@picture.polymorphic_names).to eq(%w[imageable postable])
    end
  end

  describe '#check_polymorphic' do
    it 'checks polymorphic associations and updates polymorphic instance variable and the command given as parameter' do
      command = ''
      @picture.check_polymorphic(command)
      expect(@picture.polymorphic).to eq(true)
      expect(command).to eq(' imageable:references{polymorphic} postable:references{polymorphic}')

      command = ''
      @account_history.check_polymorphic(command)
      expect(@account_history.polymorphic).to eq(false)
      expect(command).to eq('')
    end
  end

  describe '#create_model' do
    it 'creates necessary commands and run them to create models in Rails project ' do
      allow(File).to receive(:exist?).and_return(false)
      allow_any_instance_of(Object).to receive(:system) do |_, call_with|
        expect([
                 'bundle exec rails generate model Picture imageable:references{polymorphic} '\
                                                            'postable:references{polymorphic}',
                 'bundle exec rails generate model AccountHistory credit_rating:integer '\
                                                'access_time:datetime account:references'
               ]).to include call_with
      end

      @picture.create_model
      @account_history.create_model
    end
  end

  describe '#add_attributes' do
    class MockClass 
      attr_reader :name, :type
      
      def initialize(name: "mock_name", type: "mock_type")
        @name = name
        @type = type
      end
    end
    it 'adds attributes not added currently' do
      allow_any_instance_of(Item).to receive(:connect_database)

      stub_const("ActiveRecord::Base", double) 

    

      allow(ActiveRecord::Base).to receive_message_chain(:connection, :columns).and_return( [MockClass.new] )

      allow_any_instance_of(Object).to receive(:system) do |_, call_with|
        expect([
                 'bundle exec rails g migration AddColumnsToUser name:string full_name:string address:string',
               ]).to include call_with
      end
      
      @user.add_attributes
      
    end
  end

  describe '#connect_database' do
    it 'connects to database configured correctly' do
      require 'yaml'
      require 'erb'

      stub_const("ActiveRecord::Base", double) 

      allow(@user).to receive(:require)
      allow(@user).to receive(:require).with('active_record')
      allow(ActiveRecord::Base).to receive(:schema_format=)
      allow(ActiveRecord::Base).to receive(:logger=)
      allow(ActiveRecord::Base).to receive(:configurations=)
      allow(ActiveRecord::Base).to receive(:configurations).and_return({})
      allow(ActiveRecord::Base).to receive(:establish_connection)
      allow(File).to receive(:read).with('config/database.yml').and_return("default: &default")
      
      
      @user.connect_database
    end
  end
end
