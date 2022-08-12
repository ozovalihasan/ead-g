require 'item'
require 'item_clone'
require 'active_support/core_ext/string'
require 'ead'

describe ItemClone do
  before do
    ObjectSpace.garbage_collect
    @ead = EAD.new
    file = @ead.import_JSON(['./spec/sample_EAD.json'])
    
    @ead.create_items(file)

    ItemClone.all.each do |item_clone|
      item_clone.clone_parent.clones << item_clone
    end

    @account_history = ItemClone.all.select { |item| item.name == 'account_history' }[0]
    @followed = ItemClone.all.select { |item| item.name == 'followed' }[0]
    @fan = ItemClone.all.select { |item| item.name == 'fan' }[0]
    @photograph = ItemClone.all.select { |item| item.name == 'photograph' }[0]
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@photograph.id).to eq('36')
      expect(@photograph.name).to eq('photograph')
      expect(@photograph.parents_has_many.first.name).to eq('postable')
      expect(@photograph.parent_associations.first.name).to eq('has_many')
      expect(@photograph.clone_parent.name).to eq('picture')
    end
  end

  describe '#model_name' do
    it 'returns camelized clone parent name ' do
      expect(@photograph.model_name).to eq('Picture')
    end
  end

  describe '#reals_same?' do
    it 'returns boolean showing whether the real items of any item and self are same' do
      famous_person = ItemClone.all.select { |item| item.name == 'famous_person' }[0]
      expect(@fan.reals_same?(@account_history)).to eq(false)
      expect(@fan.reals_same?(famous_person)).to eq(true)
    end
  end

  describe '.find_by_name' do
    it 'returns the first clone item if its name is the searched name ' do
      expect(ItemClone.find_by_name("account_history").name).to eq("account_history")
    end
  end

  describe '#clone_name_different?' do
    it 'returns boolean showing whether the clone and its real item names are different' do
      supplier = ItemClone.all.select { |item| item.name == 'supplier' }[0]

      expect(supplier.clone_name_different?).to eq(false)
      expect(@fan.clone_name_different?).to eq(true)
    end
  end

  describe '#one_polymorphic_names?' do
    it 'returns boolean showing whether an item name is one of polymorphic names of self' do
      photograph = ItemClone.all.select { |item| item.name == 'photograph' }[0]
      postable = ItemClone.all.select { |item| item.name == 'postable' }[0]
      photograph.clone_parent.check_polymorphic('')

      expect(photograph.one_polymorphic_names?(postable)).to eq(true)
    end
  end

  describe '#real_item' do
    it 'returns the real of clone' do
      expect(@fan.real_item.name).to eq('user')
    end
  end

  describe '#update_end_model_migration_files' do
    it 'updates model and migration files of an item' do
      allow(ProjectFile).to receive(:add_belong_line) do |name, line_content|
        expect(%w[relation]).to include name
        expect([
          {"belongs_to" => ":famous_person", "class_name" => "\"User\""},
        ]).to include line_content
      end
      allow(ProjectFile).to receive(:update_line) do |name, type, keywords, line_content|
        expect(%w[add_famous_person_ref_to_relation]).to include name
        expect(%w[reference_migration]).to include type
        expect([
          /add_reference :relations/,
        ]).to include keywords
        expect([
          {"foreign_key"=>"{ to_table: :users }"},
        ]).to include line_content
      end

      famous_person = ItemClone.all.select { |item| item.name == 'famous_person' }[0]
      @followed.update_end_model_migration_files(famous_person, famous_person.associations.find {|association| association.name === 'has_many'})
      @fan.update_end_model_migration_files(famous_person, famous_person.associations.find {|association| association.name === ':through'})
    end
  end

  describe '#update_start_model_file' do
    it 'updates the model file of an item' do
      Association.set_middle_items
      
      allow(ProjectFile).to receive(:add_line) do |name, end_model, line_content|
        
        expect(%w[user user]).to include name
        expect(%w[followings famous_people]).to include end_model
        expect([{ 'has_many' => ':followings', 'class_name' => '"Relation"', 'foreign_key' => '"fan_id"' },
                { 'has_many' => ':famous_people', 'through' => ':followings' }]).to include line_content
      end

      famous_person = ItemClone.all.select { |item| item.name == 'famous_person' }[0]
      following = ItemClone.all.select { |item| item.name == 'following' }[0]
      @fan.update_start_model_file(following, @fan.associations.find(&:has_many?  ))
      @fan.update_start_model_file(famous_person, @fan.associations.find(&:through?))

      allow(ProjectFile).to receive(:add_line) do |name, end_model, line_content|
        expect(%w[postcard postcard]).to include name
        expect(%w[photographs imageables]).to include end_model
        expect([{ 'has_many' => ':photographs', 'class_name' => '"Picture"', 'as' => ':postable' },
                { 'has_many' => ':employees', 'through' => ':photographs', 'source' => ':imageable',
                  'source_type' => '"Employee" ' }]).to include line_content
      end

      imageable_employee = ItemClone.all.select { |item| item.name == 'imageable' && item.real_item.name == 'employee' }[0]
      postable_post_card = ItemClone.all.select { |item| item.name == 'postable' && item.real_item.name == 'postcard' }[0]
      photograph = ItemClone.all.select { |item| item.name == 'photograph' }[0]

      photograph.clone_parent.check_polymorphic('')

      postable_post_card.update_start_model_file(photograph, postable_post_card.associations.find(&:has_many?))
      postable_post_card.update_start_model_file(imageable_employee, postable_post_card.associations.find(&:through?))
    end
  end

  describe '#update_model' do
    it 'calls update_end_model_migration_files and update_start_model_file methods' do
      call_update_end_model_migration_files = 0
      allow_any_instance_of(ItemClone).to receive(:update_end_model_migration_files) do
        call_update_end_model_migration_files += 1
      end
      
      call_update_start_model_file = 0
      allow_any_instance_of(ItemClone).to receive(:update_start_model_file) do
        call_update_start_model_file += 1 
      end 


      following = ItemClone.all.select { |item| item.name == 'following' }[0]
      @fan.update_model(following, @fan.associations.find(&:has_many?))
      expect(call_update_end_model_migration_files).to eq(1)
      expect(call_update_start_model_file).to eq(1)
    end
  end

end
