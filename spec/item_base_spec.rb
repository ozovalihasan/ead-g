require 'ead'
require 'table'
require 'active_support/core_ext/string'

describe TableEntityBase do
  before do
    ObjectSpace.garbage_collect
    @ead = EAD.new
    file = @ead.import_JSON(['./spec/sample_EAD.json'])
    
    @ead.create_objects(file)

    Entity.all.each do |entity|
      entity.clone_parent.entities << entity
    end

    @account_history = Entity.find_by_name('account_history')
    @followed = Entity.find_by_name('followed')
    @fan = Entity.find_by_name('fan')
  end

  describe '.all' do
    it 'returns all created instances' do
      expect(TableEntityBase.all.size).to eq(25)
    end
  end

  describe '.find' do
    it 'returns found object by using id' do
      expect(TableEntityBase.find('18').name).to eq('picture')
    end
  end
end
