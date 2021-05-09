require 'item'

class Association
  attr_accessor :first_item, :second_items, :name

  def initialize(first_item, association_block)
    @first_item = first_item
    @second_items = add_second_items(association_block)
    @name = association_block.content
  end

  def add_second_items(block)
    block.sub_blocks.map do |sub_block|
      Item.new(sub_block, first_item, self)
    end
  end

  def has_many?
    name == 'has_many'
  end

  def has_one?
    name == 'has_one'
  end

  def through?
    name == ':through'
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end
end
