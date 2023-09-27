require 'table'
require 'entity'
require 'active_support/core_ext/string'
require 'ead'

describe Entity do
  before :all do
    ObjectSpace.garbage_collect

    @parsed_file = JSON.parse(File.read("#{__dir__}/sample_EAD.json"))
    parsed_tables = @parsed_file['tables']
    parsed_nodes = @parsed_file['nodes']

    @tables = parsed_tables.map do |id, parsed_table|
      Table.new(id, parsed_table)
    end

    Table.update_superclasses(parsed_tables)

    @nodes = parsed_nodes.map do |node|
      Entity.new(node)
    end
  end

  context 'class methods' do
    describe '.initialize' do
      it 'creates an instance of the class correctly' do
        photograph = Entity.find("36")

        expect(photograph.id).to eq('36')
        expect(photograph.name).to eq('photograph')
        expect(photograph.reference_entity).to eq(photograph)
        expect(photograph.table.name).to eq('picture')
        expect(photograph.table.entities.size).to eq(1)
        expect(photograph.parent_associations).to be_empty
        expect(photograph.associations).to be_empty
        expect(photograph.parents_has_one).to be_empty
        expect(photograph.parents_has_many).to be_empty
        expect(photograph.parents_has_one_through).to be_empty
        expect(photograph.parents_has_many_through).to be_empty
        expect(photograph.parents_through).to be_empty
        expect(photograph.children_has_one).to be_empty
        expect(photograph.children_has_many).to be_empty
        expect(photograph.children_has_one_through).to be_empty
        expect(photograph.children_has_many_through).to be_empty
        expect(photograph.children_through).to be_empty
      end
    end

    describe '.find_by_name' do
      it 'returns the first entity if its name is the searched name and it is a reference entity' do
        manager = Entity.find_by_name('manager')
        
        expect(manager.name).to eq('manager')
        expect(manager.reference_entity).to eq(manager)
      end
    end

    describe '.dismiss_similar_ones' do
      it 'makes reference entities of entities having same name and referring to the same table ' do
        managers = Entity.all.select {|entity| entity.name == "manager"}
        expect(managers.map(&:reference_entity).uniq.size).to eq(2)
        expect(Entity.all.count {|entity| entity.reference_entity == entity}).to eq(37)
        
        Entity.dismiss_similar_ones
        
        expect(managers.map(&:reference_entity).uniq.size).to eq(1)
        expect(Entity.all.count {|entity| entity.reference_entity == entity}).to eq(32)
      end
    end
  end

  context 'instance methods' do
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

      Association.dismiss_similar_ones
      Association.all_references.each(&:set_middle_entity)
      
      Table.all.each(&:set_polymorphic_names)

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

    describe '#root_classes_same?' do
      it 'returns boolean showing whether the tables of any entity and self are same' do
        famous_person = Entity.find_by_name('famous_person')
        expect(@fan.root_classes_same?(@account_history)).to eq(false)
        expect(@fan.root_classes_same?(famous_person)).to eq(true)
      end
    end

    describe '#table_name_different?' do
      it 'returns boolean showing whether the clone and its table names are different' do
        expect(@supplier.table_name_different?).to eq(false)
        expect(@fan.table_name_different?).to eq(true)
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
        photograph.table.set_polymorphic_names

        expect(photograph.one_polymorphic_names?(postable)).to eq(true)
      end
    end

    describe '#update_end_model_migration_files' do
      it 'prepare necessary attributes to update model and migration_files' do
        call_update_project_files = 0 
        allow_any_instance_of(Entity).to receive(:update_project_files) do |_, start_entity, end_model_line, end_migration_line|
          call_update_project_files += 1

          expect([
                   [
                     'famous_person',
                     { 'belongs_to' => ':famous_person', 'class_name' => '"User"' },
                     { 'foreign_key' => '{ to_table: :users }', 'null' => 'false' }
                   ],
                   [
                     'supervisor',
                     { 
                       'belongs_to' => ':supervisor', 
                       'optional' => 'true', 
                       'polymorphic' => 'true'
                     }, 
                     { 'null' => 'true' }
                   ],
                   [
                     'assistant_professor',
                     { 'belongs_to' => ':assistant_professor' },
                     { 
                       'column' => ':assistant_professor_id', 
                       'foreign_key' => '{ to_table: :teachers }',
                       'null' => 'true' 
                     }
                   ],
                   [
                     'client',
                     { 
                       'belongs_to' => ':client', 
                       'class_name' => '"User"', 
                       'optional' => 'true' 
                     },
                     { 'foreign_key' => '{ to_table: :users }', 'null' => 'true' }
                   ]
                 ]).to include([start_entity.name, end_model_line, end_migration_line])
        end

        famous_person = Entity.find_by_name('famous_person')
        association = famous_person.associations.find do |association|
                        association.name == 'has_many'
                      end.reference_association
        @followed.update_end_model_migration_files(famous_person, association)

        supervisor = Entity.find_by_name('supervisor')
        supervisee = Entity.find_by_name('supervisee')
        association = supervisor.associations.find do |association|
                        association.name == 'has_many'
                      end.reference_association
        supervisee.update_end_model_migration_files(supervisor, association)

        client = Entity.find_by_name('client')
        subordinate = Entity.find_by_name('subordinate')

        association = subordinate.parent_associations.find do |association|
                        association.name == 'has_many'
                      end.reference_association
        subordinate.update_end_model_migration_files(client, association)

        assistant_professor = Entity.find_by_name('assistant_professor')
        project_student = Entity.find_by_name('project_student')
        association = assistant_professor.associations.find do |association|
                        association.name == 'has_many'
                      end
        project_student.update_end_model_migration_files(assistant_professor, association)
        
        undergraduate_student = Entity.find_by_name('undergraduate_student')
        association = assistant_professor.associations.find do |association|
                        association.name == 'has_many'
                      end
        undergraduate_student.update_end_model_migration_files(assistant_professor, association)

        expect( call_update_project_files ).to eq 4
        undergraduate_student.update_end_model_migration_files(assistant_professor, association)
        expect( call_update_project_files ).to eq 4

        association = famous_person.associations.find do |association|
                        association.name == ':through'
                      end.reference_association

        expect( call_update_project_files ).to eq 4
        @fan.update_end_model_migration_files(famous_person, association)
        expect( call_update_project_files ).to eq 4
      end
    end

    describe '#update_project_files' do
      it 'updates model and migration files of a table' do
        allow_any_instance_of(Entity).to receive(:update_model_files) do |_, start_entity, end_model_line|
          expect(['famous_person']).to include start_entity.name
          expect([{ 'mock_end_model_line_key' => 'mock_end_model_line_value' }]).to include end_model_line
        end

        allow_any_instance_of(Entity).to receive(:update_migration_files) do |_, start_entity, end_migration_line|
          expect(['famous_person']).to include start_entity.name
          expect([{ 'mock_end_migration_line_key' => 'mock_end_migration_line_value' }]).to include end_migration_line
        end

        famous_person = Entity.find_by_name('famous_person')

        @followed.update_project_files(
          famous_person,
          { 'mock_end_model_line_key' => 'mock_end_model_line_value' },
          { 'mock_end_migration_line_key' => 'mock_end_migration_line_value' }
        )
      end
    end

    describe '#update_model_files' do
      it 'updates model files' do
        allow(ProjectFile).to receive(:add_belong_line) do |name, line_content|
          expect([
                   ['account', { 'mock_end_model_line_key' => 'mock_end_model_line_value' }]
                 ]).to include [name, line_content]
        end

        end_model_line = { 'mock_end_model_line_key' => 'mock_end_model_line_value' }

        supplier = Entity.find_by_name('supplier')
        account = Entity.find_by_name('account')
        account.update_model_files(supplier, end_model_line)
      end
    end

    describe '#update_migration_files' do
      it 'updates model files' do
        allow(ProjectFile).to receive(:update_line) do |name, type, keywords, line_content|
          expect([
                   [
                     'add_manager_ref_to_user',
                     'reference_migration',
                     /add_reference :users/,
                     { 'mock_end_migration_line_key' => 'mock_end_migration_line_value' }
                   ]
                 ]).to include [name, type, keywords, line_content]
        end

        end_migration_line = { 'mock_end_migration_line_key' => 'mock_end_migration_line_value' }

        manager = Entity.find_by_name('manager')
        subordinate = Entity.find_by_name('subordinate')
        subordinate.update_migration_files(manager, end_migration_line)
      end
    end

    describe '#update_start_model_file' do
      it 'updates the model file of an table' do
        Association.all_references.each(&:set_middle_entity)

        allow(ProjectFile).to receive(:add_line) do |name, end_model, line_content|
          expect(%w[user user]).to include name
          expect(%w[followings famous_people]).to include end_model
          expect([{ 
                    'has_many' => ':followings', 
                    'class_name' => '"Relation"', 
                    'foreign_key' => '"fan_id"' 
                  },
                  { 
                    'has_many' => ':famous_people', 
                    'through' => ':followings' 
                  }]).to include line_content
        end

        famous_person = Entity.find_by_name('famous_person')
        following = Entity.find_by_name('following')
        @fan.update_start_model_file(following, @fan.associations.find(&:has_many?))
        @fan.update_start_model_file(famous_person, @fan.associations.find(&:through?))

        allow(ProjectFile).to receive(:add_line) do |name, end_model, line_content|
          expect([
                   ['postcard', 'photographs',
                     { 
                       'as' => ':postable', 
                       'class_name' => '"Picture"', 
                       'has_many' => ':photographs' 
                     }
                   ],
                   ['postcard', 'imageables',
                     { 'has_many' => ':employees', 
                       'source' => ':imageable', 
                       'source_type' => '"Employee" ', 
                       'through' => ':photographs' 
                     }
                   ],
                   ['account', 'account_history', { 'has_one' => ':account_history' }],
                   ['technician', 'drivable',
                     { 
                       'has_one' => ':driver', 
                       'source' => ':drivable', 
                       'source_type' => '"Driver" ', 
                       'through' => ':car' 
                     }
                   ]
                 ]).to include [name, end_model, line_content]
        end

        imageable_employee = Entity.all.select do |entity|
                               entity.name == 'imageable' && entity.table.name == 'employee'
                             end [0]
        postable_post_card = Entity.all.select do |entity|
                               entity.name == 'postable' && entity.table.name == 'postcard'
                             end [0]
        photograph = Entity.find_by_name('photograph')

        photograph.table.set_polymorphic_names

        postable_post_card.update_start_model_file(photograph, postable_post_card.associations.find(&:has_many?))
        postable_post_card.update_start_model_file(imageable_employee, postable_post_card.associations.find(&:through?))

        account = Entity.find_by_name('account')
        account.update_start_model_file(@account_history, account.associations.find(&:has_one?))

        technician = Entity.find_by_name('technician')
        drivable_driver = Entity.all.select do |entity|
          entity.name == 'drivable' && entity.table.name == 'driver'
        end [0]
        technician.update_start_model_file(drivable_driver, technician.associations.find(&:through?))
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
