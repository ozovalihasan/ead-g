class Block
  attr_accessor :id, :content, :category, :attribute, :type, :association, :sub_blocks,
                :clone_blocks, :cloneable, :entity, :entity_clone, :clone_parent, :entity_container, :entity_association

  def initialize(id, items)
    item = items[id]
    @id = id
    @content = item['content']
    @category = item['category']
    @entity = item['entity']
    @entity_association = item['entityAssociation']
    @entity_container = item['entityContainer']
    @attribute = item['attribute']
    @type = item['type']
    @association = item['association']
    @entity_clone = item['entityClone']
    @cloneable = item['cloneable']
    @clone_blocks = item['cloneChildren']
    @clone_parent = item['cloneParent'].to_s
    @sub_blocks = []
    item['subItemIds'].each do |sub_item_id|
      sub_item_id = sub_item_id.to_s
      @sub_blocks << Block.new(sub_item_id, items)
    end
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.find(id)
    all.find { |block| block.id == id }
  end
end
