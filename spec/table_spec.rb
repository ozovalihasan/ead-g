require 'table'
require 'entity'
require 'active_support/inflector'
require 'ead'

describe Table do
  before do
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
          described_class.new(id, parsed_table)
        end

        teacher = described_class.all.find { |table| table.name == 'teacher' }

        expect(teacher.id).to eq('70')
        expect(teacher.name).to eq('teacher')
        expect(teacher.entities.size).to eq(0)
        expect(teacher.polymorphic).to be(false)
        expect(teacher.polymorphic_names).to eq({})
        expect(teacher.belongs_to_checked).to eq(Set.new)
        expect(teacher.attributes[0].name).to eq('full_name')
        expect(teacher.attributes.size).to eq(2)
        expect(teacher.superclass).to be_nil
        expect(teacher.subclasses).to eq([])

        expect(described_class.all.size).to eq(2)
      end
    end

    describe '.update_superclasses' do
      it 'updates superclass and subclasses of tables' do
        parsed_limited_file.each do |id, parsed_table|
          described_class.new(id, parsed_table)
        end

        described_class.update_superclasses(parsed_limited_file)

        university_staff = described_class.all.find { |table| table.name == 'university_staff' }

        expect(university_staff.superclass.name).to eq('teacher')
        expect(university_staff.superclass.subclasses).to contain_exactly(university_staff)
      end
    end
  end

  describe 'instance methods' do
    let(:account_history) { described_class.all.find { |table| table.name == 'account_history' } }
    let(:relation) { described_class.all.find { |table| table.name == 'relation' } }
    let(:picture) { described_class.all.find { |table| table.name == 'picture' } }
    let(:professor) { described_class.all.find { |table| table.name == 'professor' } }
    let(:student) { described_class.all.find { |table| table.name == 'student' } }
    let(:graduate_student) { described_class.all.find { |table| table.name == 'graduate_student' } }

    before do
      ObjectSpace.garbage_collect

      parsed_file = JSON.parse(File.read("#{__dir__}/sample_EAD.json"))
      parsed_tables = parsed_file['tables']
      parsed_nodes = parsed_file['nodes']
      parsed_edges = parsed_file['edges']

      @tables = parsed_tables.map do |id, parsed_table|
        described_class.new(id, parsed_table)
      end

      described_class.update_superclasses(parsed_tables)

      @nodes = parsed_nodes.map do |node|
        Entity.new(node)
      end

      Entity.dismiss_similar_ones

      @edges = parsed_edges.map do |edge|
        Association.new(edge)
      end

      Association.dismiss_similar_ones
    end

    describe '#model_name' do
      it 'returns camelized name' do
        expect(account_history.model_name).to eq('AccountHistory')
      end
    end

    describe '#root_class' do
      it 'returns the inherited table of any table or itself' do
        expect(account_history.root_class.name).to eq('account_history')
        expect(professor.root_class.name).to eq('teacher')
      end
    end

    describe '#root_class?' do
      it 'returns false if the table inherits from another table. If not, it returns true' do
        expect(account_history.root_class?).to be(true)
        expect(professor.root_class?).to be(false)
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
          account_history.generate_reference_migration(account.name)
        end
      end

      context 'if it is a polymorphic association' do
        it 'creates a migration file for the table to add a polymorphic reference' do
          allow_any_instance_of(Object).to receive(:system) do |_, call_with|
            expect(call_with).to eq 'bundle exec rails generate migration AddImageableRefToPicture imageable:belongs_to{polymorphic}'
          end

          picture.generate_reference_migration('imageable', true)
        end
      end

      context 'if the table inherits from another table' do
        it 'creates a migration file for the inherited table to add reference' do
          allow_any_instance_of(Object).to receive(:system) do |_, call_with|
            expect(call_with).to eq 'bundle exec rails generate migration AddSupervisorRefToUser supervisor:belongs_to{polymorphic}'
          end

          graduate_student.generate_reference_migration('supervisor', true)
        end
      end
    end

    describe '#set_polymorphic_names' do
      it 'updates polymorphic names used to create polymorphic associations' do
        picture.set_polymorphic_names
        expect(picture.polymorphic_names.keys).to eq(%w[postable imageable])
        expect(picture.polymorphic_names['postable'][:associations].size).to eq(2)
        expect(picture.polymorphic_names['imageable'][:associations].size).to eq(2)
        expect(picture.polymorphic).to be(true)

        student.set_polymorphic_names
        expect(student.polymorphic_names.keys).to eq(%w[teachable])
        expect(student.polymorphic_names['teachable'][:associations].size).to eq(2)
        expect(student.polymorphic).to be(true)

        graduate_student.set_polymorphic_names
        expect(graduate_student.polymorphic_names.keys).to eq(%w[supervisor])
        expect(graduate_student.polymorphic_names['supervisor'][:associations].size).to eq(4)
        expect(graduate_student.polymorphic).to be(true)

        account_history.set_polymorphic_names
        expect(account_history.polymorphic_names.keys).to eq([])
        expect(account_history.polymorphic).to be(false)
      end
    end

    describe '#create_model' do
      it 'creates necessary commands and run them to create models in Rails project' do
        allow(File).to receive(:exist?).and_return(false)

        allow_any_instance_of(Object).to receive(:system) do |_, call_with|
          expect([
                   'bundle exec rails generate model Picture',
                   'bundle exec rails generate model AccountHistory credit_rating:integer access_time:datetime',
                   'bundle exec rails generate model Relation',
                   'bundle exec rails generate model Professor --parent=UniversityStaff',
                   'bundle exec rails generate model User type'
                 ]).to include call_with
        end

        picture.create_model
        account_history.create_model
        relation.create_model
        professor.create_model

        user = described_class.all.find { |table| table.name == 'user' }
        user.create_model
      end
    end

    describe '#add_reference_migration' do
      it 'calls generate_reference_migration for parents along "has_many" and "has_one" associations' do
        call_generate_reference_migration = 0
        allow_any_instance_of(described_class).to receive(:generate_reference_migration) { |_arg, parent_name, _|
                                                    call_generate_reference_migration += 1
                                                    expect(['account']).to include parent_name
                                                  }
        allow_any_instance_of(Entity).to receive(:one_polymorphic_names?).and_return(true, false)

        expect(account_history.entities.sum { |entity| entity.parent_associations.size }).to eq(2)
        expect(account_history.entities.sum { |entity| entity.parent_associations.count(&:has_any?) }).to eq(1)
        account_history.add_reference_migration
        expect(call_generate_reference_migration).to eq(1)
      end
    end
  end
end
