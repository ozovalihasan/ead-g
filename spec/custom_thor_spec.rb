require "custom_thor"

describe CustomThor do
  it 'adds a line with line content and "belongs_to" to tempfile after the line having "class" keyword' do
    allow_any_instance_of(Thor::Actions).to receive(:inject_into_class) do |_, file_name, class_name, added_line|
      expect(file_name).to eq( "app/models/mock_name.rb" ) 
      expect(class_name).to eq( "MockName" ) 
      expect(added_line).to eq( "  belongs_to mock_line_content, other_attributes: other_attributes\n" ) 
    end

    line_content = { "belongs_to" => :mock_line_content, "other_attributes" => "other_attributes" }
    name = "mock_name"

    CustomThor.new.invoke(:add_belong_line, [], { name: name, line_content: line_content})
  end
end
