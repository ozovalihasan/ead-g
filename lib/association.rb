require 'item'

class Association
  attr_accessor :first_item, :second_item, :name

  def initialize(edge ) #first_item, association_block)
    @first_item = ItemClone.find(edge["source"])
    @second_item = ItemClone.find(edge["target"])
    
    @first_item.associations << self
    @second_item.parent_associations << self

    @name = nil
    if edge["type"] === "hasMany" 
      @first_item.children_has_many << @second_item
      @second_item.parents_has_many << @first_item

      @name = "has_many"
    elsif edge["type"] === "hasOne" 
      @first_item.children_has_one << @second_item
      @second_item.parents_has_one << @first_item
      
      @name = "has_one"
    elsif edge["type"] === "through" 
      @first_item.children_through << @second_item
      @second_item.parents_through << @first_item
      
      @name = ":through"
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
