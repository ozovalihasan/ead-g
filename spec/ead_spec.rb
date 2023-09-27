require 'ead'
require 'active_support/core_ext/string'

describe EAD do
  before :each do
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

    it 'raises an error if the version of JSON file is not compatible' do
      shown_texts = []
      allow_any_instance_of(Object).to receive(:puts) do |_, str|
        shown_texts << str
      end
      incompatible_file = { version: '0.3.0' }.to_json
      allow(File).to receive(:read).and_return(incompatible_file)
      expect { @ead.import_JSON([]) }.to raise_error('Incompatible version')
      expect([
               "\n\n----------------",
               "\e[31m\ngem install ead -v 0.3.0\e[0m",
               "\e[31mVersions of your EAD file and the gem are not compatible. So, you may have " \
               "some unexpected results.To run your EAD file correctly, please run\e[0m",
               "----------------\n\n"
             ]).to match_array shown_texts
    end
  end

  describe '#create_objects' do
    it 'creates all necessary instances of Table, Entity and Assocation' do
      count_association_call_set_middle_entity = 0
      allow_any_instance_of(Association).to receive(:set_middle_entity) do 
        count_association_call_set_middle_entity += 1
      end

      count_table_set_polymorphic_names = 0
      allow_any_instance_of(Table).to receive(:set_polymorphic_names) do 
        count_table_set_polymorphic_names += 1
      end
      
      @ead.create_objects(@file)

      expect(Table.all.size).to eq(2)
      expect(Entity.all.size).to eq(4)
      expect(Entity.all.select {|entity| entity.reference_entity == entity}.size).to eq(2)
      expect(Association.all.size).to eq(2)
      expect(Association.all_references.size).to eq(1)
      expect(count_association_call_set_middle_entity).to eq(1)
      expect(count_table_set_polymorphic_names).to eq(2)
    end
  end

  describe '.check_implement_objects' do
    it 'creates all necessary instances of classes and create models and associations' do
      call_create_model = 0
      allow_any_instance_of(Table).to receive(:create_model) { |_arg| call_create_model += 1 }

      call_add_reference_migration = 0
      allow_any_instance_of(Table).to receive(:add_reference_migration) { |_arg| call_add_reference_migration += 1 }

      call_update_model_from_entity = 0
      allow_any_instance_of(Association).to receive(:update_model_from_entity) { |_arg|
                                              call_update_model_from_entity += 1
                                            }

      @ead.create_objects(@file)
      @ead.check_implement_objects

      expect(call_create_model).to eq(2)
      expect(call_add_reference_migration).to eq(2)
      expect(call_update_model_from_entity).to eq(1)
    end
  end

  describe '.check_latest_version' do
    context 'if there is an internet connection' do
      it 'checks the latest version of the gem and prints a warning about new release of the gem' do
        response = RestClient::Response.new [{ name: '' }].to_json

        allow(RestClient).to receive(:get).and_return(response)

        shown_texts = []
        allow_any_instance_of(Object).to receive(:puts) do |_, str|
          shown_texts << str
        end

        @ead.check_latest_version

        expect([
                 "\n\n----------------",
                 "\n\e[33mA new version of this gem has been released. Please check it. https://github.com/ozovalihasan/ead-g/releases\e[0m",
                 "\n----------------\n\n"
               ]).to match_array(shown_texts)
      end
    end

    context "if there isn't an internet connection" do
      it 'prints a warning about unstable internet connection' do
        response = StandardError

        allow(RestClient).to receive(:get).and_return(response)

        expect { @ead.check_latest_version }.to output(
          "\n\n----------------" \
          "\n\n" \
          "\e[31m" \
          'If you want to check the latest version of this gem, ' \
          'you need to have a stable internet connection.' \
          "\e[0m" \
          "\n\n----------------\n\n"
        ).to_stdout
      end
    end
  end

  describe '.start' do
    it 'starts all process' do
      call_check_latest_version = 0
      allow_any_instance_of(EAD).to receive(:check_latest_version) { |_arg| call_check_latest_version += 1 }

      call_import_JSON = 0
      allow_any_instance_of(EAD).to receive(:import_JSON) { |_arg| call_import_JSON += 1 }

      call_create_objects = 0
      allow_any_instance_of(EAD).to receive(:create_objects) { |_arg| call_create_objects += 1 }

      call_check_implement_objects = 0
      allow_any_instance_of(EAD).to receive(:check_implement_objects) { |_arg| call_check_implement_objects += 1 }

      @ead.start([])

      expect(call_check_latest_version).to eq(1)
      expect(call_import_JSON).to eq(1)
      expect(call_create_objects).to eq(1)
      expect(call_check_implement_objects).to eq(1)
    end

    it 'completes all necessary actions completely' do
      allow_any_instance_of(Object).to receive(:puts)

      response = RestClient::Response.new [{ name: '' }].to_json
      allow(RestClient).to receive(:get).and_return(response)

      changes = []
      allow(ProjectFile).to receive(:add_belong_line) do |name, line_content|
        changes << { file_name: name, type: 'model', line: line_content, action: 'added' }
      end
      allow(ProjectFile).to receive(:add_line) do |name, end_model, line_content|
        changes << { file_name: name, type: 'model', end_model: end_model, line: line_content, action: 'added' }
      end
      allow(ProjectFile).to receive(:update_line) do |name, type, keywords, line_content|
        changes << { file_name: name, type: type, keywords: keywords, line: line_content, action: 'updated' }
      end

      allow_any_instance_of(Object).to receive(:system) do |_, command|
        changes << "command #{command} run"
      end

      ead = EAD.new

      ead.start(['./spec/sample_EAD.json'])

      expect(changes.size).to eq(89)
      expect(changes).to match_array(
        [
          "command bundle exec rails generate model Director --parent=Employee run", 
          "command bundle exec rails generate model Technician run", 
          "command bundle exec rails generate model Driver run", 
          "command bundle exec rails generate model Car --parent=Vehicle run", 
          "command bundle exec rails generate model Vehicle type run", 
          "command bundle exec rails generate model UniversityStaff --parent=Teacher run", 
          "command bundle exec rails generate model Teacher type full_name:string branch:string run", 
          "command bundle exec rails generate model GraduateStudent --parent=Student run", 
          "command bundle exec rails generate model Student --parent=User run", 
          "command bundle exec rails generate model AssistantProfessor --parent=UniversityStaff run", 
          "command bundle exec rails generate model Professor --parent=UniversityStaff run", 
          "command bundle exec rails generate model Employee --parent=User run", 
          "command bundle exec rails generate model Picture run", 
          "command bundle exec rails generate model Product run", 
          "command bundle exec rails generate model Letter run", 
          "command bundle exec rails generate model Postcard run", 
          "command bundle exec rails generate model User type run", 
          "command bundle exec rails generate model Relation run", 
          "command bundle exec rails generate model AccountHistory credit_rating:integer access_time:datetime run", 
          "command bundle exec rails generate model Account run", 
          "command bundle exec rails generate model Supplier run", 
          "command bundle exec rails generate migration AddDrivableRefToVehicle drivable:belongs_to{polymorphic} run", 
          "command bundle exec rails generate migration AddTechnicianRefToVehicle technician:belongs_to run", 
          "command bundle exec rails generate migration AddSupervisorRefToUser supervisor:belongs_to{polymorphic} run", 
          "command bundle exec rails generate migration AddTeachableRefToUser teachable:belongs_to{polymorphic} run", 
          "command bundle exec rails generate migration AddTeachableRefToUser teachable:belongs_to{polymorphic} run", 
          "command bundle exec rails generate migration AddAssistantProfessorRefToUser assistant_professor:belongs_to run", 
          "command bundle exec rails generate migration AddAssistantProfessorRefToUser assistant_professor:belongs_to run", 
          "command bundle exec rails generate migration AddManagerRefToUser manager:belongs_to run", 
          "command bundle exec rails generate migration AddPostableRefToPicture postable:belongs_to{polymorphic} run", 
          "command bundle exec rails generate migration AddImageableRefToPicture imageable:belongs_to{polymorphic} run", 
          "command bundle exec rails generate migration AddCustomerRepresentativeRefToUser customer_representative:belongs_to{polymorphic} run", 
          "command bundle exec rails generate migration AddFanRefToRelation fan:belongs_to run", 
          "command bundle exec rails generate migration AddFamousPersonRefToRelation famous_person:belongs_to run", 
          "command bundle exec rails generate migration AddAccountRefToAccountHistory account:belongs_to run", 
          "command bundle exec rails generate migration AddSupplierRefToAccount supplier:belongs_to run", 
          {:file_name=>"car", :type=>"model", :line=>{"belongs_to"=>":drivable", "polymorphic"=>"true"}, :action=>"added"}, 
          {:file_name=>"add_drivable_ref_to_vehicle", :type=>"reference_migration", :keywords=>/add_reference :vehicles/, :line=>{"null"=>"true"}, :action=>"updated"}, 
          {:file_name=>"user", :type=>"model", :end_model=>"cars", :line=>{"has_many"=>":cars", "as"=>":drivable"}, :action=>"added"}, 
          {:file_name=>"driver", :type=>"model", :end_model=>"cars", :line=>{"has_many"=>":cars", "as"=>":drivable"}, :action=>"added"}, 
          {:file_name=>"user", :type=>"model", :line=>{"belongs_to"=>":customer_representative", "optional"=>"true", "polymorphic"=>"true"}, :action=>"added"}, 
          {:file_name=>"add_customer_representative_ref_to_user", :type=>"reference_migration", :keywords=>/add_reference :users/, :line=>{"null"=>"true"}, :action=>"updated"}, 
          {:file_name=>"director", :type=>"model", :end_model=>"clients", :line=>{"has_many"=>":clients", "class_name"=>"\"User\"", "as"=>":customer_representative"}, :action=>"added"}, 
          {:file_name=>"employee", :type=>"model", :end_model=>"clients", :line=>{"has_many"=>":clients", "class_name"=>"\"User\"", "as"=>":customer_representative"}, :action=>"added"}, 
          {:file_name=>"technician", :type=>"model", :end_model=>"drivable", :line=>{"has_one"=>":driver", "through"=>":car", "source"=>":drivable", "source_type"=>"\"Driver\" "}, :action=>"added"}, 
          {:file_name=>"car", :type=>"model", :line=>{"belongs_to"=>":technician"}, :action=>"added"}, 
          {:file_name=>"add_technician_ref_to_vehicle", :type=>"reference_migration", :keywords=>/add_reference :vehicles/, :line=>{"null"=>"true"}, :action=>"updated"}, 
          {:file_name=>"technician", :type=>"model", :end_model=>"car", :line=>{"has_one"=>":car"}, :action=>"added"}, 
          {:file_name=>"student", :type=>"model", :line=>{"belongs_to"=>":assistant_professor"}, :action=>"added"}, 
          {:file_name=>"add_assistant_professor_ref_to_user", :type=>"reference_migration", :keywords=>/add_reference :users/, :line=>{"null"=>"true", "foreign_key"=>"{ to_table: :teachers }", "column"=>":assistant_professor_id"}, :action=>"updated"}, 
          {:file_name=>"assistant_professor", :type=>"model", :end_model=>"undergraduate_students", :line=>{"has_many"=>":undergraduate_students", "class_name"=>"\"Student\""}, :action=>"added"}, 
          {:file_name=>"assistant_professor", :type=>"model", :end_model=>"project_students", :line=>{"has_many"=>":project_students", "class_name"=>"\"Student\""}, :action=>"added"}, 
          {:file_name=>"student", :type=>"model", :line=>{"belongs_to"=>":teachable", "polymorphic"=>"true"}, :action=>"added"}, 
          {:file_name=>"add_teachable_ref_to_user", :type=>"reference_migration", :keywords=>/add_reference :users/, :line=>{"null"=>"true"}, :action=>"updated"}, 
          {:file_name=>"teacher", :type=>"model", :end_model=>"students", :line=>{"has_many"=>":students", "as"=>":teachable"}, :action=>"added"}, 
          {:file_name=>"graduate_student", :type=>"model", :line=>{"belongs_to"=>":supervisor", "optional"=>"true", "polymorphic"=>"true"}, :action=>"added"}, 
          {:file_name=>"add_supervisor_ref_to_user", :type=>"reference_migration", :keywords=>/add_reference :users/, :line=>{"null"=>"true"}, :action=>"updated"}, 
          {:file_name=>"teacher", :type=>"model", :end_model=>"supervisees", :line=>{"has_many"=>":supervisees", "class_name"=>"\"GraduateStudent\"", "as"=>":supervisor"}, :action=>"added"}, 
          {:file_name=>"professor", :type=>"model", :end_model=>"doctoral_students", :line=>{"has_many"=>":doctoral_students", "class_name"=>"\"Student\"", "as"=>":teachable"}, :action=>"added"}, 
          {:file_name=>"assistant_professor", :type=>"model", :end_model=>"supervisees", :line=>{"has_many"=>":supervisees", "class_name"=>"\"GraduateStudent\"", "as"=>":supervisor"}, :action=>"added"}, 
          {:file_name=>"professor", :type=>"model", :end_model=>"supervisees", :line=>{"has_many"=>":supervisees", "class_name"=>"\"GraduateStudent\"", "as"=>":supervisor"}, :action=>"added"}, 
          {:file_name=>"supplier", :type=>"model", :end_model=>"account_history", :line=>{"has_one"=>":account_history", "through"=>":account"}, :action=>"added"}, 
          {:file_name=>"account_history", :type=>"model", :line=>{"belongs_to"=>":account"}, :action=>"added"}, 
          {:file_name=>"add_account_ref_to_account_history", :type=>"reference_migration", :keywords=>/add_reference :account_histories/, :line=>{"null"=>"false"}, :action=>"updated"}, 
          {:file_name=>"account", :type=>"model", :end_model=>"account_history", :line=>{"has_one"=>":account_history"}, :action=>"added"}, 
          {:file_name=>"account", :type=>"model", :line=>{"belongs_to"=>":supplier"}, :action=>"added"}, 
          {:file_name=>"add_supplier_ref_to_account", :type=>"reference_migration", :keywords=>/add_reference :accounts/, :line=>{"null"=>"false"}, :action=>"updated"}, 
          {:file_name=>"supplier", :type=>"model", :end_model=>"account", :line=>{"has_one"=>":account"}, :action=>"added"}, 
          {:file_name=>"postcard", :type=>"model", :end_model=>"imageables", :line=>{"has_many"=>":employees", "through"=>":photographs", "source"=>":imageable", "source_type"=>"\"Employee\" "}, :action=>"added"}, 
          {:file_name=>"letter", :type=>"model", :end_model=>"imageables", :line=>{"has_many"=>":products", "through"=>":photographs", "source"=>":imageable", "source_type"=>"\"Product\" "}, :action=>"added"}, 
          {:file_name=>"picture", :type=>"model", :line=>{"belongs_to"=>":imageable", "polymorphic"=>"true"}, :action=>"added"}, 
          {:file_name=>"add_imageable_ref_to_picture", :type=>"reference_migration", :keywords=>/add_reference :pictures/, :line=>{"null"=>"false"}, :action=>"updated"}, 
          {:file_name=>"employee", :type=>"model", :end_model=>"photographs", :line=>{"has_many"=>":photographs", "class_name"=>"\"Picture\"", "as"=>":imageable"}, :action=>"added"}, 
          {:file_name=>"product", :type=>"model", :end_model=>"photographs", :line=>{"has_many"=>":photographs", "class_name"=>"\"Picture\"", "as"=>":imageable"}, :action=>"added"}, 
          {:file_name=>"picture", :type=>"model", :line=>{"belongs_to"=>":postable", "polymorphic"=>"true"}, :action=>"added"}, 
          {:file_name=>"add_postable_ref_to_picture", :type=>"reference_migration", :keywords=>/add_reference :pictures/, :line=>{"null"=>"false"}, :action=>"updated"}, 
          {:file_name=>"postcard", :type=>"model", :end_model=>"photographs", :line=>{"has_many"=>":photographs", "class_name"=>"\"Picture\"", "as"=>":postable"}, :action=>"added"}, 
          {:file_name=>"letter", :type=>"model", :end_model=>"photographs", :line=>{"has_many"=>":photographs", "class_name"=>"\"Picture\"", "as"=>":postable"}, :action=>"added"}, 
          {:file_name=>"user", :type=>"model", :end_model=>"fans", :line=>{"has_many"=>":fans", "through"=>":followeds"}, :action=>"added"}, 
          {:file_name=>"user", :type=>"model", :end_model=>"famous_people", :line=>{"has_many"=>":famous_people", "through"=>":followings"}, :action=>"added"}, 
          {:file_name=>"relation", :type=>"model", :line=>{"belongs_to"=>":famous_person", "class_name"=>"\"User\""}, :action=>"added"}, 
          {:file_name=>"add_famous_person_ref_to_relation", :type=>"reference_migration", :keywords=>/add_reference :relations/, :line=>{"null"=>"false", "foreign_key"=>"{ to_table: :users }"}, :action=>"updated"}, 
          {:file_name=>"user", :type=>"model", :end_model=>"followeds", :line=>{"has_many"=>":followeds", "class_name"=>"\"Relation\"", "foreign_key"=>"\"famous_person_id\""}, :action=>"added"}, 
          {:file_name=>"relation", :type=>"model", :line=>{"belongs_to"=>":fan", "class_name"=>"\"User\""}, :action=>"added"}, 
          {:file_name=>"add_fan_ref_to_relation", :type=>"reference_migration", :keywords=>/add_reference :relations/, :line=>{"null"=>"false", "foreign_key"=>"{ to_table: :users }"}, :action=>"updated"}, 
          {:file_name=>"user", :type=>"model", :end_model=>"followings", :line=>{"has_many"=>":followings", "class_name"=>"\"Relation\"", "foreign_key"=>"\"fan_id\""}, :action=>"added"}, 
          {:file_name=>"employee", :type=>"model", :line=>{"belongs_to"=>":manager", "optional"=>"true", "class_name"=>"\"Director\""}, :action=>"added"}, 
          {:file_name=>"add_manager_ref_to_user", :type=>"reference_migration", :keywords=>/add_reference :users/, :line=>{"null"=>"true", "foreign_key"=>"{ to_table: :users }", "column"=>":manager_id"}, :action=>"updated"}, 
          {:file_name=>"director", :type=>"model", :end_model=>"subordinates", :line=>{"has_many"=>":subordinates", "class_name"=>"\"Employee\"", "foreign_key"=>"\"manager_id\""}, :action=>"added"}
        ]
      )
    end
  end
end
