require 'item'

class Association
  attr_accessor :first_item, :second_item, :name, :middle_items_has_one, :middle_items_has_many, :through_item

  def initialize(edge ) #first_item, association_block)
    @first_item = ItemClone.find(edge["source"])
    @second_item = ItemClone.find(edge["target"])
    @through_item = nil

    @middle_items_has_one = []
    @middle_items_has_many = []

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

      @through_item = ItemClone.find(edge["data"]["throughNodeId"])
      
      @name = ":through"
    end
  end
  
  def self.set_middle_items
    associations = all.select(&:through?)
    need_one_more_loop = true

    while need_one_more_loop
      need_one_more_loop = false
      associations.each do |association|

        source = association.first_item
        target = association.second_item
        through_item = association.through_item
        
        if (
          (source.children_has_many.include? through_item) || (target.parents_has_many.include? through_item) ||
          (source.children_has_many_through.include? through_item) || (target.parents_has_many_through.include? through_item)
        )
          unless association.middle_items_has_many.include? through_item
            need_one_more_loop = true
            association.middle_items_has_many << through_item
            source.children_has_many_through << target
            target.parents_has_many_through << source
          end
        else
          unless association.middle_items_has_one.include? through_item
            need_one_more_loop = true
            association.middle_items_has_one << through_item
            source.children_has_one_through << target
            target.parents_has_one_through << source
          end
        end
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
