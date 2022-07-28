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

  describe '#initialize' do
    it 'creates an instance of the class correctly' do
      expect(@followed.id).to eq('48')
      expect(@followed.name).to eq('followed')
      expect(@followed.twin_name).to eq('following')
      expect(@followed.parent.name).to eq('famous_person')
      expect(@followed.parent_association.name).to eq('has_many')
      expect(@followed.associations[0].name).to eq(':through')
      expect(@account_history.clone_parent.attributes[0].name).to eq('credit_rating')
    end
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(ItemBase.all.size).to eq(24)
    end
  end

  describe '.find' do
    it 'returns found item by using id' do
      expect(ItemBase.find('25').name).to eq('supplier')
    end
  end
end
