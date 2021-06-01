class ItemBase
  attr_accessor :name, :id, :twin_name

  def initialize(block, _parent = nil, _parent_association = nil)
    @id = block.id
    @name = block.content.split(' || ')[0].underscore.singularize
    @twin_name = block.content.split(' || ')[1]&.underscore&.singularize
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.find(id)
    all.find { |item| item.id == id }
  end
end
