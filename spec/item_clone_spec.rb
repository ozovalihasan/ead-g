require 'item'
require 'item_clone'
require 'block'
require 'active_support/core_ext/string'
require 'ead'

describe ItemClone do
  before do
    ObjectSpace.garbage_collect
    @ead = EAD.new
    @ead.import_JSON(['./spec/sample_EAD.json'])
    ead_id = '9'
    block = Block.find(ead_id)
    @ead.create_items(block)

    ItemClone.all.each do |item_clone|
      parent = Item.find(item_clone.clone_parent)
      item_clone.clone_parent = Item.find(item_clone.clone_parent)
      parent.clones << item_clone
    end

    @photograph = ItemClone.all.select { |item| item.name == 'photograph' }[0]
    # @picture = Item.all.select { |item| item.name == 'picture' }[0]
  end

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@photograph.id).to eq('17')
      expect(@photograph.name).to eq('photograph')
      expect(@photograph.parent.name).to eq('imageable')
      expect(@photograph.parent_association.name).to eq('has_many')
      expect(@photograph.attributes.size).to eq(0)
      expect(@photograph.associations.first.name).to eq(':through')
      expect(@photograph.clone_parent.name).to eq('picture')
    end
  end

  describe '#model_name' do
    it 'returns camelized clone parent name ' do
      expect(@photograph.model_name).to eq('Picture')
    end
  end
end
