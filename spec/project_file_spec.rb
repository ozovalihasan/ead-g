require 'ead'
require 'project_file'

describe ProjectFile do
  describe '.open_close' do
    describe 'opens, updates and closes a file' do
      before(:each) do
        allow(Dir).to receive(:glob) do |name|
          expect([
                   './db/migrate/*_mock_name.rb'
                 ]).to include name
        end.and_return(['mock_found_file'])

        allow(File).to receive(:open) do |file_name|
          expect([
                   './app/models/model_update.rb',
                   './db/migrate/migration_update.rb',
                   './db/migrate/reference_migration_update.rb'
                 ]).to include file_name

          double('file', readline: 'mock tempfile', close: '')
        end

        allow(File).to receive(:new) do |file_name|
          expect([
                   './app/models/mock_name.rb',
                   'mock_found_file'
                 ]).to include file_name

          double('file', readline: 'mock file', close: '')
        end

        allow(FileUtils).to receive(:mv) do |deleted_file, changed_file|
          expect([
                   './db/migrate/migration_update.rb',
                   './app/models/model_update.rb',
                   './db/migrate/reference_migration_update.rb'
                 ]).to include deleted_file
          expect(['./app/models/mock_name.rb', 'mock_found_file']).to include changed_file
        end
      end

      it 'works on a model file' do
        result = ''
        ProjectFile.open_close('mock_name', 'model') do |temp, tempfile|
          result = "#{temp.readline} #{tempfile.readline}"
        end

        expect(result).to eq(
          'mock file mock tempfile'
        )
      end

      it 'works on a migration file' do
        result2 = ''
        ProjectFile.open_close('mock_name', 'migration') do |temp, tempfile|
          result2 = "#{temp.readline} #{tempfile.readline}"
        end

        expect(result2).to eq(
          'mock file mock tempfile'
        )
      end

      it 'works on a reference migration file' do
        result3 = ''
        ProjectFile.open_close('mock_name', 'reference_migration') do |temp, tempfile|
          result3 = "#{temp.readline} #{tempfile.readline}"
        end

        expect(result3).to eq(
          'mock file mock tempfile'
        )
      end
    end
  end

  describe '.update_line' do
    it 'adds a line with line content to tempfile' do
      file = ["def change\n", "  add_reference :mock_names, :mock_names_second, null: false\n", "end\n"]
      tempfile = ''
      allow(ProjectFile).to receive(:open_close) do |name, type, &block|
        block.call(file, tempfile)
        expect('mock_name').to include name
        expect(['reference_migration']).to include type
      end

      mock_line_content = { 'null' => 'true', 'foreign_key' => '{ to_table: :mock_table_name }' }
      ProjectFile.update_line('mock_name', 'reference_migration', /add_reference :mock_names/, mock_line_content)

      expect(tempfile).to eq(
        "def change\n" \
        "  add_reference :mock_names, :mock_names_second, null: true, foreign_key: { to_table: :mock_table_name }\n" \
        "end\n"
      )
    end
  end

  describe '.add_line' do
    it 'adds a line with line content to tempfile' do
      file = ["class Mock\n", "end\n"]
      tempfile = ''
      allow(ProjectFile).to receive(:open_close) do |name, type, &block|
        block.call(file, tempfile)
        expect('mock_name').to include name
        expect(['model']).to include type
      end

      mock_line_content = { 'has_many' => 'mocks', 'mock' => 'content' }
      ProjectFile.add_line('mock_name', 'mock_end_model', mock_line_content)

      expect(tempfile).to eq("class Mock\n  has_many mocks, mock: content\nend\n")
    end
  end

  describe '.add_belong_line' do
    it 'adds a line with line content and "belongs_to" to tempfile after the line having "class" keyword' do
      file = [
        "class Mock\n",
        "  has_many mocks, mock: content\n",
        "end\n"
      ]
      tempfile = ''
      allow(ProjectFile).to receive(:open_close) do |name, type, &block|
        block.call(file, tempfile)
        expect('mock_name').to include name
        expect(['model']).to include type
      end

      mock_line_content = { 'belongs_to' => 'mock2', 'mock2' => 'content2' }
      ProjectFile.add_belong_line('mock_name', mock_line_content)

      expect(tempfile).to eq(
        "class Mock\n" \
        "  belongs_to mock2, mock2: content2\n" \
        "  has_many mocks, mock: content\n" \
        "end\n"
      )
    end
  end
end
