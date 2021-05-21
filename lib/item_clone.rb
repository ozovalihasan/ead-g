require 'item_base'

class ItemClone < ItemBase
  attr_accessor :clone_parent

  def initialize(block, parent = nil, parent_association = nil)
    super(block, parent, parent_association)
    @clone_parent = block.clone_parent
  end

  def model_name
    clone_parent.name.camelize
  end
end
