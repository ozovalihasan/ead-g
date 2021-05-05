class Association
  attr_accessor :first_item, :second_items, :name

  def initialize(first_item, item)
    @first_item = first_item
    @second_items = []
    @name = item.content
    if item.sub_blocks
      item.sub_blocks.map do |sub_block|
        @second_items << Item.new(sub_block, { item: first_item, association: self }, first_item.parent[:item])
      end
    end
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end
  
end
