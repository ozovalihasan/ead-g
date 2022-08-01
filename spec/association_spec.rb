require 'association'
require 'item_clone'
require 'ead'

describe Association do
  before(:all) do
    ObjectSpace.garbage_collect
    file = JSON.parse(File.read("#{__dir__}/association_spec_sample.json"))
    file = file.to_json

    @nodes = JSON.parse(file)['nodes']
    @edges = JSON.parse(file)['edges']
    @tables = JSON.parse(file)['tables']

    
    @tables = @tables.map do |(id)|
      Item.new(id, @tables)
    end

    @nodes.map! do |node|
      ItemClone.new(node)
    end

    @edges.map! do |edge|
      Association.new(edge)
    end
    
    
    @item1 =  ItemClone.all.select { |item| item.name == 'entity1' }[0]
    @association1 = @item1.associations.first
    @item2 = ItemClone.find_by_name("entity2")
    @association2 = @item2.associations.first
    @item3 = ItemClone.find_by_name("entity3")
    @association3 = @item2.associations.last
    @item4 = ItemClone.find_by_name("entity4")
  end

  describe '#initialize' do
    it 'is created correctly' do
      expect(@association1.first_item.class).to eq(ItemClone)
      expect(@association1.name).to eq('has_many')
      expect(@association1.middle_items_has_many).to eq([])
      expect(@association1.middle_items_has_one).to eq([])
      
      expect(@item2.associations.first).to eq(@association2)
      expect(@item2.parent_associations.any? @association1).to eq(true)
      
      expect(@item2.parents_has_many.any? @item1).to eq(true)
      expect(@item1.children_has_many.any? @item2).to eq(true)
      expect(@item3.parents_has_one.any? @item2).to eq(true)
      expect(@item2.children_has_one.any? @item3).to eq(true)
      expect(@item4.parents_through.any? @item3).to eq(true)
      expect(@item3.children_through.any? @item4).to eq(true)
    end
  end

  describe '.set_middle_items' do
    it "sets all middle items of amy 'through' association " do
      Association.set_middle_items

      item5 = ItemClone.find_by_name("entity5")
      item6 = ItemClone.find_by_name("entity6")
      item7 = ItemClone.find_by_name("entity7")
      association = item7.associations.find(&:through?)
      expect(association.middle_items_has_many).to include(item5)

      association2 = @item3.associations.find(&:through?)
      expect(association2.middle_items_has_one).to include(@item2)
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
      expect(Association.all.size).to eq(9)
    end
  end
end
