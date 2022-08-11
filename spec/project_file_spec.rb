require 'ead'
require 'project_file'

describe ProjectFile do
  describe '.update_line' do
    it 'opens, updates and closes a file' do
      allow(Dir).to receive(:glob) do |name|
        expect(['./db/migrate/*_mock_names.rb']).to include name
      end.and_return(['mock_found_file'])

      allow(File).to receive(:open).and_return('mock tempfile')
      allow(File).to receive(:new).and_return('mock file')
      allow_any_instance_of(String).to receive(:close)
      allow(FileUtils).to receive(:mv) do |deleted_file, changed_file|
        expect(['./db/migrate/migration_update.rb', './app/models/model_update.rb']).to include deleted_file
        expect(['./app/models/mock_name.rb', 'mock_found_file']).to include changed_file
      end

      result = ''
      ProjectFile.open_close('mock_name', 'model') do |temp, tempfile|
        result << temp
        result << ' '
        result << tempfile
      end

      expect(result).to eq(
        'mock file mock tempfile'
      )

      result2 = ''
      ProjectFile.open_close('mock_name', 'migration') do |temp, tempfile|
        result2 << tempfile
        result2 << ' '
        result2 << temp
      end

      expect(result2).to eq(
        'mock tempfile mock file'
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
        "class Mock\n"\
        "  belongs_to mock2, mock2: content2\n"\
        "  has_many mocks, mock: content\n"\
        "end\n"
      )
    end
  end
end
