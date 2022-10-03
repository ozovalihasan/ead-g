require 'association'
require 'entity'
require 'ead'

describe Association do
  before(:all) do
    ObjectSpace.garbage_collect
    
    file = JSON.parse(File.read("#{__dir__}/association_spec_sample.json"))
    
    parsed_nodes = file['nodes']
    parsed_edges = file['edges']
    parsed_tables = file['tables']

    @tables = parsed_tables.map do |(id)|
      Table.new(id, parsed_tables[id])
    end

    Table.update_superclasses(parsed_tables)
    

    @nodes = parsed_nodes.map do |node|
      Entity.new(node)
    end

    @edges = parsed_edges.map do |edge|
      Association.new(edge)
    end

    @entity1 = Entity.find_by_name('entity1')
    @association1 = @entity1.associations.first
    @entity2 = Entity.find_by_name('entity2')
    @association2 = @entity2.associations.first
    @entity3 = Entity.find_by_name('entity3')
    @association3 = @entity2.associations.last
    @entity4 = Entity.find_by_name('entity4')
  end

  describe '#initialize' do
    it 'is created correctly' do
      expect(@association1.first_entity.class).to eq(Entity)
      expect(@association1.name).to eq('has_many')
      expect(@association1.middle_entities_has_many).to eq([])
      expect(@association1.middle_entities_has_one).to eq([])

      expect(@entity2.associations.first).to eq(@association2)
      expect(@entity2.parent_associations.any?(@association1)).to eq(true)

      expect(@entity2.parents_has_many.any?(@entity1)).to eq(true)
      expect(@entity1.children_has_many.any?(@entity2)).to eq(true)
      expect(@entity3.parents_has_one.any?(@entity2)).to eq(true)
      expect(@entity2.children_has_one.any?(@entity3)).to eq(true)
      expect(@entity4.parents_through.any?(@entity3)).to eq(true)
      expect(@entity3.children_through.any?(@entity4)).to eq(true)
    end
  end

  describe '.check_middle_entities_include' do
    it "sets all middle entities of any 'through' association if the through entity of the association" \
       ' is the given entity' do
      entity3 = Entity.find_by_name('entity3')
      entity8 = Entity.find_by_name('entity8')

      Association.check_middle_entities_include(@entity4)
      expect(entity3.children_has_one_through.map(&:id)).not_to include(@entity4.id)
      expect(@entity4.parents_has_one_through.map(&:id)).not_to include(entity3.id)

      Association.check_middle_entities_include(@entity2)
      expect(entity3.children_has_one_through.map(&:id)).to include(@entity4.id)
      expect(@entity4.parents_has_one_through.map(&:id)).to include(entity3.id)
      expect(entity3.children_has_one_through).to include(entity8)
      expect(entity8.parents_has_one_through).to include(entity3)
    end
  end

  describe '#set_middle_entity' do
    it "sets the middle entity of a 'through' association " do
      Association.all.each(&:set_middle_entity)
            
      entity3 = Entity.find_by_name('entity3')
      entity5 = Entity.find_by_name('entity5')
      entity6 = Entity.find_by_name('entity6')
      entity7 = Entity.find_by_name('entity7')
      entity8 = Entity.find_by_name('entity8')

      association = entity7.associations.find(&:through?)
      expect(association.middle_entities_has_one).to include(entity5)
      expect(entity7.children_has_one_through).to include(entity6)
      expect(entity6.parents_has_one_through).to include(entity7)

      association2 = @entity2.associations.find(&:through?)
      expect(association2.middle_entities_has_many).to include(entity7)

      expect(entity3.children_has_many_through).to include(entity7)
      expect(entity7.parents_has_many_through).to include(entity3)

      expect(entity3.children_has_many_through).to include(entity5)
      expect(entity5.parents_has_many_through).to include(entity3)

      expect(entity3.children_has_one_through).to include(@entity4)
      expect(@entity4.parents_has_one_through).to include(entity3)

      expect(entity3.children_has_one_through).to include(entity8)
      expect(entity8.parents_has_one_through).to include(entity3)
      
    end
  end

  describe '#has_many?' do
    it "returns whether an instance's name is 'has_many'" do
      expect(@association1.has_many?).to eq(true)
    end
  end

  describe '#has_one?' do
    it "returns whether an instance's name is 'has_one'" do
      expect(@association2.has_one?).to eq(true)
    end
  end

  describe '#has_any?' do
    it "returns whether an instance's name is 'has_many' or 'has_one'" do
      expect(@association1.has_any?).to eq(true)
      expect(@association2.has_any?).to eq(true)
    end
  end

  describe '#through?' do
    it "returns whether an instance's name is ':through'" do
      expect(@association3.through?).to eq(true)
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(Association.all.size).to eq(13)
    end
  end
end
