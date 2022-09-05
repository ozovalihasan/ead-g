require 'table'
require 'entity'
require 'active_support/core_ext/string'
require 'ead'

describe Table do
  before do
    ObjectSpace.garbage_collect
    @ead = EAD.new
    file = @ead.import_JSON(['./spec/sample_EAD.json'])

    @ead.create_objects(file)

    Entity.all.each do |entity|
      entity.clone_parent.entities << entity
    end

    @account_history = Table.all.select { |table| table.name == 'account_history' }[0]
    @relation = Table.all.select { |table| table.name == 'relation' }[0]
    @picture = Table.all.select { |table| table.name == 'picture' }[0]
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@account_history.id).to eq('12')
      expect(@account_history.name).to eq('account_history')
      expect(@account_history.entities.size).to eq(1)
      expect(@account_history.polymorphic).to eq(false)
      expect(@account_history.polymorphic_names).to eq([])
      expect(@account_history.attributes[0].name).to eq('credit_rating')
      expect(@account_history.attributes.size).to eq(2)
    end
  end

  describe '#model_name' do
    it 'returns camelized name ' do
      expect(@account_history.model_name).to eq('AccountHistory')
    end
  end

  describe '#add_references' do
    it 'adds references to command' do
      allow_any_instance_of(Object).to receive(:system) do |_, call_with|
        expect([
                 'bundle exec rails generate migration AddAccountRefToAccountHistory account:references'
               ]).to include call_with
      end

      command = ''
      account = Entity.find_by_name('account')
      @account_history.add_references(account)
    end
  end

  describe '#add_polymorphic_reference' do
    it 'adds polymorphic reference to command' do
      command = ''
      @account_history.add_polymorphic_reference(command, 'mock_polymorphic_name')
      expect(command).to eq(' mock_polymorphic_name:references{polymorphic}')
    end
  end

  describe '#update_polymorphic_names' do
    it 'adds polymorphic reference to command' do
      @picture.update_polymorphic_names
      expect(@picture.polymorphic_names).to eq(%w[postable imageable])
    end
  end

  describe '#check_polymorphic' do
    it 'checks polymorphic associations and updates polymorphic instance variable and the command given as parameter' do
      command = ''
      @picture.check_polymorphic(command)
      expect(@picture.polymorphic).to eq(true)
      expect(command).to eq(' postable:references{polymorphic} imageable:references{polymorphic}')

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
                 'bundle exec rails generate model Picture' \
                 ' postable:references{polymorphic} imageable:references{polymorphic}',
                 'bundle exec rails generate model AccountHistory' \
                 ' credit_rating:integer access_time:datetime',
                 'bundle exec rails generate model Relation'
               ]).to include call_with
      end

      @picture.create_model
      @account_history.create_model
      @relation.create_model
    end
  end

  describe '#add_reference_migration' do
    it 'creates necessary commands and run them to create models in Rails project ' do
      allow(File).to receive(:exist?).and_return(false)
      allow_any_instance_of(Object).to receive(:system) do |_, call_with|
        expect([
                 'bundle exec rails generate model AccountHistory credit_rating:integer access_time:datetime',
                 'bundle exec rails generate model Relation'
               ]).to include call_with
      end

      @picture.check_polymorphic('')
      @picture.add_reference_migration

      @account_history.create_model
      @relation.create_model
    end
  end
end
