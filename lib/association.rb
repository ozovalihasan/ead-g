require 'item'

class Association
  attr_accessor :first_item, :second_item, :name

  def initialize(edge ) #first_item, association_block)
    @first_item = ItemClone.find(edge["source"])
    @second_item = ItemClone.find(edge["target"])
    
    ItemClone.find(edge["source"]).add_to_associations(self)
    ItemClone.find(edge["target"]).add_to_parent_associations(self)
    @name = if edge["type"] === "hasMany" 
      "has_many"
    elsif edge["type"] === "hasOne" 
      "has_one"
    elsif edge["type"] === "through" 
      ":through"
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
