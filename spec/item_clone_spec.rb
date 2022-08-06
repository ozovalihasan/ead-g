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


  # describe '#grand' do
  #   it 'returns parent item of parent item' do
  #     expect(@account_history.grand.name).to eq('supplier')
  #   end
  # end

  # describe '#grand_association' do
  #   it 'returns the association between parent and grand parent items' do
  #     expect(@account_history.grand_association.name).to eq('has_one')
  #   end
  # end

  # describe '#grand_has_many?' do
  #   it "returns boolean showing whether the grand association is 'has_many' or not" do
  #     expect(@account_history.grand_has_many?).to eq(false)
  #     expect(@fan.grand_has_many?).to eq(true)
  #   end
  # end

  # describe '#grand_has_one?' do
  #   it "returns boolean showing whether the grand association is 'has_one' or not" do
  #     expect(@account_history.grand_has_one?).to eq(true)
  #     expect(@fan.grand_has_one?).to eq(false)
  #   end
  # end

  # describe '#grand_real_self_real?' do
  #   it 'returns boolean showing whether the real items of grand association and self are same' do
  #     expect(@account_history.grand_real_self_real?).to eq(false)
  #     expect(@fan.grand_real_self_real?).to eq(true)
  #   end
  # end

  describe '#reals_same?' do
    it 'returns boolean showing whether the real items of any item and self are same' do
      famous_person = ItemClone.all.select { |item| item.name == 'famous_person' }[0]
      expect(@fan.reals_same?(@account_history)).to eq(false)
      expect(@fan.reals_same?(famous_person)).to eq(true)
    end
  end

  # describe '#parent_through?' do
  #   it "returns boolean showing whether the association between parent item and self is 'through?'" do
  #     expect(@account_history.parent_through?).to eq(true)
  #     expect(@fan.parent_through?).to eq(true)
  #     expect(@followed.parent_through?).to eq(false)
  #   end
  # end

  # describe '#parent_has_many?' do
  #   it "returns boolean showing whether the association between parent item and self is 'has_many?'" do
  #     expect(@fan.parent_has_many?).to eq(false)
  #     expect(@followed.parent_has_many?).to eq(true)
  #   end
  # end

  # describe '#parent_has_one?' do
  #   it "returns boolean showing whether the association between parent item and self is 'has_one?'" do
  #     account = ItemClone.all.select { |item| item.name == 'account' }[0]
  #     expect(@followed.parent_has_one?).to eq(false)
  #     expect(account.parent_has_one?).to eq(true)
  #   end
  # end

  # describe '#parent_has_any?' do
  #   it "returns boolean showing whether the association between parent item and self is 'has_one?' or 'has_many?'" do
  #     account = ItemClone.all.select { |item| item.name == 'account' }[0]
  #     expect(@followed.parent_has_any?).to eq(true)
  #     expect(account.parent_has_any?).to eq(true)
  #     expect(@fan.parent_has_any?).to eq(false)
  #   end
  # end

  # describe '#parent_through_has_one?' do
  #   it "returns boolean showing whether the association between parent item and grand parent is 'has_one?'"\
  #     "and the association between parent item and self is 'through?'" do
  #     expect(@account_history.parent_through_has_one?).to eq(true)
  #     expect(@fan.parent_through_has_one?).to eq(false)
  #   end
  # end

  # describe '#parent_through_has_many?' do
  #   it "returns boolean showing whether the association between parent item and grand parent is 'has_many?'"\
  #     "and the association between parent item and self is 'through?'" do
  #     expect(@account_history.parent_through_has_many?).to eq(false)
  #     expect(@fan.parent_through_has_many?).to eq(true)
  #   end
  # end

  # describe '#through_association' do
  #   it "returns the ':through' association between self and any child" do
  #     account = ItemClone.all.select { |item| item.name == 'account' }[0]

  #     expect(account.through_association.name).to eq(':through')
  #   end
  # end

  # describe '#through_child?' do
  #   it "returns the first item having ':through' association" do
  #     account = ItemClone.all.select { |item| item.name == 'account' }[0]

  #     expect(account.through_association.name).to eq(':through')
  #   end
  # end

  # describe '#through?' do
  #   it 'returns boolean showing whether an item exists or not' do
  #     expect(@fan.through?(@followed)).to eq(true)
  #     expect(@fan.through?(nil)).to eq(false)
  #   end
  # end

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

  # describe '#grand_many_through_reals_same?' do
  #   it 'returns boolean showing whether'\
  #       " there is 'has_many :through' association between its grand parent given as parameter and self"\
  #       ' and reals of its grand parent and self are same ' do
  #     famous_person = ItemClone.all.select { |item| item.name == 'famous_person' }[0]

  #     expect(@fan.grand_many_through_reals_same?(famous_person)).to eq(true)
  #   end
  # end

  # describe '#parent_has_many_reals_same_through_child?' do
  #   it 'returns boolean showing whether'\
  #       " there is 'has_many :through' association between its child given as parameter and parent"\
  #       ' and reals of its parent and child are same ' do
  #     expect(@followed.parent_has_many_reals_same_through_child?(@fan)).to eq(true)
  #   end
  # end

  describe '#update_end_model_migration_files' do
    it 'updates model and migration files of an item' do
      allow(ProjectFile).to receive(:update_line) do |name, type, keywords, line_content|
        expect(%w[user user user user]).to include name
        expect(%w[model migration model migration]).to include type
        expect([/belongs_to :followed/,
                /t.references :followed/,
                /belongs_to :famous_person/,
                /t.references :famous_person/]).to include keywords
        expect([{ 'class_name' => '"Relation"' },
                { 'foreign_key' => '{ to_table: :relations }' },
                { 'optional' => 'true', 'class_name' => '"User"' },
                { 'null' => 'true', 'foreign_key' => '{ to_table: :users }' }]).to include line_content
      end

      famous_person = ItemClone.all.select { |item| item.name == 'famous_person' }[0]
      @fan.update_end_model_migration_files(@followed, @followed.parent_associations[0])
      @fan.update_end_model_migration_files(famous_person, @fan.associations.find {|association| association.name === 'has_many'})
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

  # describe '#parent_through_add_associations' do
  #   it 'calls update_model method if the parent association of an item is ":though"' do
  #     call_update_model = 0
  #     allow_any_instance_of(ItemClone).to receive(:update_model) { call_update_model += 1 }

  #     postable = ItemClone.all.select { |item| item.name == 'postable' && item.real_item.name == 'postcard' }[0]

  #     @fan.parent_through_add_associations
  #     expect(call_update_model).to eq(3)
  #     postable.parent_through_add_associations
  #     expect(call_update_model).to eq(6)
  #     @account_history.parent_through_add_associations
  #     expect(call_update_model).to eq(8)
  #   end
  # end

  # describe '#add_associations' do
  #   it 'calls update_model for each association and '\
  #     "parent_through_add_associations if the parent association is ':through'" do
  #     call_parent_through_add_associations = 0
  #     allow_any_instance_of(ItemClone).to receive(:parent_through_add_associations) do
  #       call_parent_through_add_associations += 1
  #     end

  #     call_update_model = 0
  #     allow_any_instance_of(ItemClone).to receive(:update_model) { call_update_model += 1 }

  #     imageable = ItemClone.all.select { |item| item.name == 'imageable' && item.real_item.name == 'employee' }[0]

  #     @fan.add_associations
  #     expect(call_update_model).to eq(0)
  #     expect(call_parent_through_add_associations).to eq(1)
  #     imageable.add_associations
  #     expect(call_update_model).to eq(1)
  #     expect(call_parent_through_add_associations).to eq(1)
  #   end
  # end
end
