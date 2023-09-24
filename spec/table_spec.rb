require 'table'
require 'entity'
require 'active_support/core_ext/string'
require 'ead'

describe Table do
  before :each do
    require 'table'

    ObjectSpace.garbage_collect
  end

  describe 'class methods' do
    let!(:parsed_limited_file) do
      parsed_file = JSON.parse(File.read("#{__dir__}/sample_EAD.json"))
      @parsed_tables = parsed_file['tables']

      {
        '70' => parsed_file['tables']['70'],
        '74' => parsed_file['tables']['74']
      }
    end

    describe '.initialize' do
      it 'creates an instance of the class correctly' do
        parsed_limited_file.each do |id, parsed_table|
          Table.new(id, parsed_table)
        end

        teacher = Table.all.find { |table| table.name == 'teacher' }

        expect(teacher.id).to eq('70')
        expect(teacher.name).to eq('teacher')
        expect(teacher.entities.size).to eq(0)
        expect(teacher.polymorphic).to eq(false)
        expect(teacher.polymorphic_names).to eq([])
        expect(teacher.attributes[0].name).to eq('full_name')
        expect(teacher.attributes.size).to eq(2)
        expect(teacher.superclass).to eq(nil)
        expect(teacher.subclasses).to eq([])

        expect(Table.all.size).to eq(2)
      end
    end

    describe '.update_superclasses' do
      it 'updates superclass and subclasses of tables ' do
        parsed_limited_file.each do |id, parsed_table|
          Table.new(id, parsed_table)
        end

        Table.update_superclasses(parsed_limited_file)

        university_staff = Table.all.find { |table| table.name == 'university_staff' }

        expect(university_staff.superclass.name).to eq('teacher')
        expect(university_staff.superclass.subclasses).to match_array([university_staff])
      end
    end
  end

  describe 'instance methods' do
    before :all do
      ObjectSpace.garbage_collect

      parsed_file = JSON.parse(File.read("#{__dir__}/sample_EAD.json"))
      parsed_tables = parsed_file['tables']
      parsed_nodes = parsed_file['nodes']
      parsed_edges = parsed_file['edges']

      @tables = parsed_tables.map do |id, parsed_table|
        Table.new(id, parsed_table)
      end

      Table.update_superclasses(parsed_tables)

      @nodes = parsed_nodes.map do |node|
        Entity.new(node)
      end

      @edges = parsed_edges.map do |edge|
        Association.new(edge)
      end

      @account_history = Table.all.find { |table| table.name == 'account_history' }
      @relation = Table.all.find { |table| table.name == 'relation' }
      @picture = Table.all.find { |table| table.name == 'picture' }
      @professor = Table.all.find { |table| table.name == 'professor' }
      @student = Table.all.find { |table| table.name == 'student' }
      @graduate_student = Table.all.find { |table| table.name == 'graduate_student' }
    end

    describe '#model_name' do
      it 'returns camelized name ' do
        expect(@account_history.model_name).to eq('AccountHistory')
      end
    end

    describe '#root_class' do
      it 'returns the inherited table of any table or itself' do
        expect(@account_history.root_class.name).to eq('account_history')
        expect(@professor.root_class.name).to eq('teacher')
      end
    end

    describe '#root_class?' do
      it 'returns false if the table inherits from another table. If not, it returns true' do
        expect(@account_history.root_class?).to eq(true)
        expect(@professor.root_class?).to eq(false)
      end
    end

    describe '#generate_reference_migration' do
      context "if it isn't a polymorphic association" do
        it 'creates a migration file for the table to add a reference' do
          allow_any_instance_of(Object).to receive(:system) do |_, call_with|
            expect([
                     'bundle exec rails generate migration AddAccountRefToAccountHistory account:belongs_to'
                   ]).to include call_with
          end

          account = Entity.find_by_name('account')
          @account_history.generate_reference_migration(account.name)
        end
      end

      context 'if it is a polymorphic association' do
        it 'creates a migration file for the table to add a polymorphic reference' do
          allow_any_instance_of(Object).to receive(:system) do |_, call_with|
            expect([
                     'bundle exec rails generate migration AddImageableRefToPicture imageable:belongs_to{polymorphic}'
                   ]).to include call_with
          end

          @picture.generate_reference_migration('imageable', true)
        end
      end

      context 'if the table inherits from another table' do
        it 'creates a migration file for the inherited table to add reference' do
          allow_any_instance_of(Object).to receive(:system) do |_, call_with|
            expect([
                     'bundle exec rails generate migration AddSupervisorRefToUser supervisor:belongs_to{polymorphic}'
                   ]).to include call_with
          end

          @graduate_student.generate_reference_migration('supervisor', true)
        end
      end
    end

    describe '#set_polymorphic_names' do
      it 'updates polymorphic names used to create polymorphic associations' do
        @picture.set_polymorphic_names
        expect(@picture.polymorphic_names).to eq(%w[postable imageable])
        expect(@picture.polymorphic).to eq(true)

        @student.set_polymorphic_names
        expect(@student.polymorphic_names).to eq(%w[teachable])
        expect(@student.polymorphic).to eq(true)

        @graduate_student.set_polymorphic_names
        expect(@graduate_student.polymorphic_names).to eq(%w[supervisor])
        expect(@graduate_student.polymorphic).to eq(true)

        @account_history.set_polymorphic_names
        expect(@account_history.polymorphic_names).to eq([])
        expect(@account_history.polymorphic).to eq(false)
      end
    end

    describe '#create_model' do
      it 'creates necessary commands and run them to create models in Rails project ' do
        allow(File).to receive(:exist?).and_return(false)

        allow_any_instance_of(Object).to receive(:system) do |_, call_with|
          expect([
                   'bundle exec rails generate model Picture',
                   'bundle exec rails generate model AccountHistory ' \
                   'credit_rating:integer access_time:datetime',
                   'bundle exec rails generate model Relation',
                   'bundle exec rails generate model Professor --parent=UniversityStaff',
                   'bundle exec rails generate model User type'
                 ]).to include call_with
        end

        @picture.create_model
        @account_history.create_model
        @relation.create_model
        @professor.create_model

        user = Table.all.find { |table| table.name == 'user' }
        user.create_model
      end
    end

    describe '#add_reference_migration' do
      it 'calls generate_reference_migration if the association between itself and its parent is not a polymorphic association' do
        call_generate_reference_migration = 0
        allow_any_instance_of(Table).to receive(:generate_reference_migration) { |_arg|
                                          call_generate_reference_migration += 1
                                        }
        allow_any_instance_of(Entity).to receive(:one_polymorphic_names?).and_return(true, false)

        @account_history.add_reference_migration
        expect(call_generate_reference_migration).to eq(0)

        @account_history.add_reference_migration
        expect(call_generate_reference_migration).to eq(1)
      end
    end
  end
end
