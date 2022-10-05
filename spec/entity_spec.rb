require 'table'
require 'entity'
require 'active_support/core_ext/string'
require 'ead'

describe Entity do
  
  before :all do
    @parsed_file = JSON.parse(File.read("#{__dir__}/sample_EAD.json"))
    parsed_tables = @parsed_file['tables']
    
    @tables = parsed_tables.map do |id, parsed_table|
      Table.new(id, parsed_table)
    end

    Table.update_superclasses(parsed_tables)
  end

  context "class methods" do
    describe '.initialize' do
      it 'creates an instance of the class correctly' do
        photograph = Entity.new(@parsed_file['nodes'].find {|node| node["id"] == "36"})
        
        expect(photograph.id).to eq('36')
        expect(photograph.name).to eq('photograph')
        expect(photograph.clone_parent.name).to eq('picture')
        expect(photograph.clone_parent.entities.size).to eq(1)
        expect(photograph.parent_associations).to be_empty()
        expect(photograph.associations).to be_empty()
        expect(photograph.parents_has_one).to be_empty()
        expect(photograph.parents_has_many).to be_empty()
        expect(photograph.parents_has_one_through).to be_empty()
        expect(photograph.parents_has_many_through).to be_empty()
        expect(photograph.parents_through).to be_empty()
        expect(photograph.children_has_one).to be_empty()
        expect(photograph.children_has_many).to be_empty()
        expect(photograph.children_has_one_through).to be_empty()
        expect(photograph.children_has_many_through).to be_empty()
        expect(photograph.children_through).to be_empty()
      end
    end
  
    describe '.find_by_name' do
      it 'returns the first entity if its name is the searched name ' do
        parsed_nodes = @parsed_file['nodes']

        @nodes = parsed_nodes.map do |node|
          Entity.new(node)
        end

        expect(Entity.find_by_name('account_history').name).to eq('account_history')
        expect(Entity.find_by_name('account_history').id).to eq('47')
      end
    end
    
  end
  
  context "instance methods" do  
    before :all do
      ObjectSpace.garbage_collect
      parsed_nodes = @parsed_file['nodes']
      parsed_edges = @parsed_file['edges']

      @nodes = parsed_nodes.map do |node|
        Entity.new(node)
      end

      @edges = parsed_edges.map do |edge|
        Association.new(edge)
      end

      @account_history = Entity.find_by_name('account_history')
      @followed = Entity.find_by_name('followed')
      @fan = Entity.find_by_name('fan')
      @photograph = Entity.find_by_name('photograph')
      @supplier = Entity.find_by_name('supplier')
    end

    describe '#model_name' do
      it 'returns camelized clone parent name ' do
        expect(@photograph.model_name).to eq('Picture')
      end
    end

    describe '#root_class_same?' do
      it 'returns boolean showing whether the tables of any entity and self are same' do
        famous_person = Entity.find_by_name('famous_person')
        expect(@fan.root_class_same?(@account_history)).to eq(false)
        expect(@fan.root_class_same?(famous_person)).to eq(true)
      end
    end

    describe '#clone_name_different?' do
      it 'returns boolean showing whether the clone and its table names are different' do
        expect(@supplier.clone_name_different?).to eq(false)
        expect(@fan.clone_name_different?).to eq(true)
      end
    end

    describe '#root_class_name_different??' do
      it 'returns boolean showing whether the clone and its table names are different' do
        expect(@account_history.root_class_name_different?).to eq(false)
        expect(@fan.root_class_name_different?).to eq(true)
      end
    end

    describe '#one_polymorphic_names?' do
      it 'returns boolean showing whether a entity name is one of polymorphic names of self' do
        photograph = Entity.find_by_name('photograph')
        postable = Entity.find_by_name('postable')
        photograph.clone_parent.check_polymorphic('')

        expect(photograph.one_polymorphic_names?(postable)).to eq(true)
      end
    end

    describe '#table' do
      it 'returns the table of the entity' do
        expect(@fan.table.name).to eq('user')
      end
    end

    describe '#update_end_model_migration_files' do
      it 'updates model and migration files of a table' do
        allow_any_instance_of(Entity).to receive(:update_project_files) do |_,start_entity, end_model_line, end_migration_line|
          
          expect([
                  [
                    "famous_person", 
                    {"belongs_to" => ":famous_person", "class_name" => "\"User\""}, 
                    {"foreign_key" => "{ to_table: :users }", "null" => "false"}
                  ],
                  [
                    "supervisor", 
                    {"belongs_to" => ":supervisor", "class_name" => "\"Teacher\""}, 
                    {"foreign_key" => "{ to_table: :teachers }", "null" => "true"}
                  ],
                  [
                    "assistant_professor", 
                    {"belongs_to" => ":assistant_professor"}, 
                    {"column" => ":assistant_professor_id", "foreign_key" => "{ to_table: :teachers }", "null" => "true"}
                  ],
                  [
                    "client", 
                    {"belongs_to" => ":client", "class_name" => "\"User\"", "optional" => "true"}, 
                    {"foreign_key" => "{ to_table: :users }", "null" => "true"}
                  ]
                ]).to include( [ start_entity.name, end_model_line, end_migration_line ] )
        end
        
        famous_person = Entity.find_by_name('famous_person')
        association = famous_person.associations.find do |association|
          association.name == 'has_many'
        end
        @followed.update_end_model_migration_files( famous_person, association )

        supervisor = Entity.find_by_name('supervisor')
        supervisee = Entity.find_by_name('supervisee')
        association = supervisor.associations.find do |association|
          association.name == 'has_many'
        end                                                                  
        supervisee.update_end_model_migration_files( supervisor, association )

        assistant_professor = Entity.find_by_name('assistant_professor')
        project_student = Entity.find_by_name('project_student')
        association = assistant_professor.associations.find do |association|
          association.name == 'has_many'
        end                                                                  
        project_student.update_end_model_migration_files( assistant_professor, association )
        
        client = Entity.find_by_name('client')
        subordinate = Entity.find_by_name('subordinate')
        association = subordinate.associations.find do |association|
          association.name == 'has_many'
        end                                                                  
        subordinate.update_end_model_migration_files( client, association )

        association = famous_person.associations.find do |association|
          association.name == ':through'
        end                                                                  
        expect(
          @fan.update_end_model_migration_files( famous_person, association )
        ).to eq nil
      end
    end
    
    describe '#update_project_files' do
      it 'updates model and migration files of a table' do
        allow(ProjectFile).to receive(:add_belong_line) do |name, line_content|
          expect(%w[relation]).to include name
          expect([
                  { 'belongs_to' => ':famous_person', 'class_name' => '"User"' }
                ]).to include line_content
        end
        
        allow(ProjectFile).to receive(:update_line) do |name, type, keywords, line_content|
          expect(%w[add_famous_person_ref_to_relation]).to include name
          expect(%w[reference_migration]).to include type
          expect([
                  /add_reference :relations/
                ]).to include keywords
          expect([
                  {
                    'foreign_key' => '{ to_table: :users }',
                    'null' => 'false'
                  }
                ]).to include line_content
        end

        famous_person = Entity.find_by_name('famous_person')
        association = famous_person.associations.find do |association|
          association.name == 'has_many'
        end

        @followed.update_end_model_migration_files(
          famous_person, 
          association  
        )

        association = famous_person.associations.find do |association|
          association.name == ':through'
        end                                                                  

        @fan.update_end_model_migration_files( famous_person, association )
      end
    end

    describe '#update_start_model_file' do
      it 'updates the model file of an table' do
        Association.all.each(&:set_middle_entity)

        allow(ProjectFile).to receive(:add_line) do |name, end_model, line_content|
          expect(%w[user user]).to include name
          expect(%w[followings famous_people]).to include end_model
          expect([{ 'has_many' => ':followings', 'class_name' => '"Relation"', 'foreign_key' => '"fan_id"' },
                  { 'has_many' => ':famous_people', 'through' => ':followings' }]).to include line_content
        end

        famous_person = Entity.find_by_name('famous_person')
        following = Entity.find_by_name('following')
        @fan.update_start_model_file(following, @fan.associations.find(&:has_many?))
        @fan.update_start_model_file(famous_person, @fan.associations.find(&:through?))

        allow(ProjectFile).to receive(:add_line) do |name, end_model, line_content|
          expect(%w[postcard postcard]).to include name
          expect(%w[photographs imageables]).to include end_model
          expect([{ 'has_many' => ':photographs', 'class_name' => '"Picture"', 'as' => ':postable' },
                  { 'has_many' => ':employees', 'through' => ':photographs', 'source' => ':imageable',
                    'source_type' => '"Employee" ' }]).to include line_content
        end

        imageable_employee = Entity.all.select do |entity|
                              entity.name == 'imageable' && entity.table.name == 'employee'
                            end [0]
        postable_post_card = Entity.all.select do |entity|
                              entity.name == 'postable' && entity.table.name == 'postcard'
                            end [0]
        photograph = Entity.find_by_name('photograph')

        photograph.clone_parent.check_polymorphic('')

        postable_post_card.update_start_model_file(photograph, postable_post_card.associations.find(&:has_many?))
        postable_post_card.update_start_model_file(imageable_employee, postable_post_card.associations.find(&:through?))
      end
    end

    describe '#update_model' do
      it 'calls update_end_model_migration_files and update_start_model_file methods' do
        call_update_end_model_migration_files = 0
        allow_any_instance_of(Entity).to receive(:update_end_model_migration_files) do
          call_update_end_model_migration_files += 1
        end

        call_update_start_model_file = 0
        allow_any_instance_of(Entity).to receive(:update_start_model_file) do
          call_update_start_model_file += 1
        end

        following = Entity.find_by_name('following')
        @fan.update_model(following, @fan.associations.find(&:has_many?))
        expect(call_update_end_model_migration_files).to eq(1)
        expect(call_update_start_model_file).to eq(1)
      end
    end
  end
end
