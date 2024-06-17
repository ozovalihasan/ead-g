require 'ead'
require 'table'
require 'active_support/inflector'

describe TableEntityBase do
  before do
    ObjectSpace.garbage_collect
    file = File.read("#{__dir__}/sample_EAD.json")

    parsed_tables = JSON.parse(file)['tables']
    parsed_nodes = JSON.parse(file)['nodes']

    @tables = parsed_tables.map do |(id)|
      Table.new(id, parsed_tables[id])
    end

    @nodes = parsed_nodes.map do |node|
      Entity.new(node)
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(described_class.all.size).to eq(60)
    end
  end

  describe '.find' do
    it 'returns found object by using id' do
      expect(described_class.find('18').name).to eq('picture')
    end
  end
end
