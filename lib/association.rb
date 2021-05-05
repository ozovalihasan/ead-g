class Association
  attr_accessor :first_item, :second_items, :name

  def initialize(first_item, association_block)
    @first_item = first_item
    @second_items = []
    @name = association_block.content
    if association_block.sub_blocks
      association_block.sub_blocks.map do |sub_block|
        @second_items << Item.new(sub_block, { item: first_item, association: self }, first_item.parent[:item])
      end
    end
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

end
