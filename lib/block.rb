class Block
  attr_accessor :id, :content, :category, :attribute_container, :attribute, :type, :association, :sub_blocks

  def initialize(id, items)
    item = items[id]
    @id = id
    @content = item['content']
    @category = item['category']
    @attribute_container = item['attributeContainer']
    @attribute = item['attribute']
    @type = item['type']
    @association = item['association']
    @sub_blocks = []
    item['subItemIds'].map do |sub_item_id|
      sub_item_id = sub_item_id.to_s
      @sub_blocks << Block.new(sub_item_id, items)
    end
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.find(id)
    all.each { |block| return block if block.id == id }
  end
end
