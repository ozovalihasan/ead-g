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
    
    
    @item1 = @account_history = ItemClone.all.select { |item| item.name == 'entity1' }[0]
    @association1 = @item1.associations.first
    @item2 = @association1.second_item
    @association2 = @item2.associations.first
    @item3 = @association2.second_item
    @association3 = @item2.associations.last
    @item4 = @association3.second_item
  end

  describe '#initialize' do
    it 'is created correctly' do
      expect(@association1.first_item.class).to eq(ItemClone)
      expect(@association1.name).to eq('has_many')
      expect(@item2.associations.first).to eq(@association2)
      expect(@item2.parent_associations.any? @association1).to eq(true)
      expect(@item2.parents_has_many.any? @item1).to eq(true)
      expect(@item1.children_has_many.any? @item2).to eq(true)
      expect(@item3.parents_has_one.any? @item2).to eq(true)
      expect(@item2.children_has_one.any? @item3).to eq(true)
      expect(@item4.parents_through.any? @item2).to eq(true)
      expect(@item2.children_through.any? @item4).to eq(true)
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
      expect(Association.all.size).to eq(4)
    end
  end
end
