require "custom_thor"

describe CustomThor do
  describe ".update_line" do
    it 'update the line containing the "keywords"' do
      allow_any_instance_of(Thor::Actions).to receive(:gsub_file) do |_, file_name, regexp, &block|
        
        expect(file_name).to eq("./db/migrate/*_mock_name.rb") 
        expect(regexp).to eq(/^.*mock keyword.*$/) 
        result = block.call("add_reference :mock, :second_mock, null: false")
        expect(result).to eq(
          "add_reference :mock, :second_mock, null: true, foreign_key: { to_table: :users }"
        ) 
      end

      name = "mock_name"
      line_content = { 'null' => "true", "foreign_key" => "{ to_table: :users }" }
      keywords = "mock keyword"
      type = "reference_migration"

      CustomThor.new.invoke(:update_line, [], {
        keywords: keywords,
        line_content: line_content,
        name: name,
        type: type
      })
    end
  end
  
  describe ".add_belong_line" do
    it 'adds a line with line content and "belongs_to" to tempfile after the line having "class" keyword' do
      allow_any_instance_of(Thor::Actions).to receive(:inject_into_class) do |_, file_name, class_name, added_line|
        expect(file_name).to eq("app/models/mock_name.rb")
        expect(class_name).to eq("MockName")
        expect(added_line).to eq("  belongs_to mock_line_content, other_attributes: other_attributes\n")
      end

      line_content = { "belongs_to" => :mock_line_content, "other_attributes" => "other_attributes" }
      name = "mock_name"

      CustomThor.new.invoke(:add_belong_line, [], { name: name, line_content: line_content})
    end
  end
end
