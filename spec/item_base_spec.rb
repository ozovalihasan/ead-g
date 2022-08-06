require 'ead'
require 'item'
require 'active_support/core_ext/string'

describe ItemBase do
  before do
    ObjectSpace.garbage_collect
    @ead = EAD.new
    file = @ead.import_JSON(['./spec/sample_EAD.json'])
    
    @ead.create_items(file)

    ItemClone.all.each do |item_clone|
      item_clone.clone_parent.clones << item_clone
    end

    @account_history = ItemClone.all.select { |item| item.name == 'account_history' }[0]
    @followed = ItemClone.all.select { |item| item.name == 'followed' }[0]
    @fan = ItemClone.all.select { |item| item.name == 'fan' }[0]
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(ItemBase.all.size).to eq(25)
    end
  end

  describe '.find' do
    it 'returns found item by using id' do
      expect(ItemBase.find('18').name).to eq('picture')
    end
  end
end
