require 'ead'
require 'project_file'

describe ProjectFile do

  class MockCustomThor
  end

  describe '.update_line' do
    it 'invokes CustomThor#update_line ' do
      
      allow(CustomThor).to receive(:new).and_return(MockCustomThor.new)
      allow_any_instance_of(MockCustomThor).to receive(:invoke) do |_, method_name, _, third|
        expect(method_name).to eq :update_line
        expect(third).to eq(
          {
            keywords: "mock keyword",
            line_content: {"foreign_key"=>"{ to_table: :users }", "null"=>"true"},
            name: "mock_name",
            type: "reference_migration"
          }
        ) 
      end

      name = "mock_name"
      line_content = { 'null' => "true", "foreign_key" => "{ to_table: :users }" }
      keywords = "mock keyword"
      type = "reference_migration"
      ProjectFile.update_line(name, type, keywords, line_content)

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
    it 'invokes CustomThor#add_belong_line ' do
      
      allow(CustomThor).to receive(:new).and_return(MockCustomThor.new)
      allow_any_instance_of(MockCustomThor).to receive(:invoke) do |_, method_name, _, third|
        expect(method_name).to eq :add_belong_line
        expect(third).to eq(
          {line_content: {"belongs_to"=>"mock2", "mock2"=>"content2"}, name: "mock"} 
        ) 
      end
      
      mock_line_content = { 'belongs_to' => 'mock2', 'mock2' => 'content2' }
      ProjectFile.add_belong_line('mock', mock_line_content)

    end
  end
end
