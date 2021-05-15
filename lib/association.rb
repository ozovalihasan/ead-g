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
      if sub_block.entity
        Item.new(sub_block, first_item, self)
      elsif sub_block.entity_clone
        ItemClone.new(sub_block, first_item, self)
      end
    end
  end

  def has_many?
    name == 'has_many'
  end

  def has_one?
    name == 'has_one'
  end

  def has_any?
    has_one? || has_many?
  end

  def through?
    name == ':through'
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end
end
