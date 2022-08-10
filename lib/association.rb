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

  def self.check_middle_items_include(clone_item)
    associations = Association.all.select {|association| association.through_item == clone_item }
    associations.each do |association| 
      unless ((association.middle_items_has_many.include? clone_item ) || (association.middle_items_has_one.include? clone_item ))
        association.set_middle_item
      end
    end
  end

  def set_middle_item
    source = first_item
    target = second_item
    
    if (
      (
        (
          source.parents_has_many + 
          source.parents_has_many_through + 
          source.parents_has_one + 
          source.parents_has_one_through + 
          source.children_has_many + 
          source.children_has_many_through + 
          source.children_has_one + 
          source.children_has_one_through 
        ).include?(through_item) 
      ) &&
      (
        (
          target.parents_has_many + 
          target.parents_has_many_through + 
          target.parents_has_one + 
          target.parents_has_one_through + 
          target.children_has_many + 
          target.children_has_many_through + 
          target.children_has_one + 
          target.children_has_one_through 
        ).include?(through_item) || (
          through_item.parents_has_many.map(&:clone_parent).include?(target.clone_parent)  || 
          through_item.parents_has_one.map(&:clone_parent).include?(target.clone_parent)
        )
      )
    )
      if (
        (
          source.children_has_many.include?(through_item) || 
          source.children_has_many_through.include?(through_item)
        ) || (
          target.parents_has_many.include?(through_item) ||
          target.parents_has_many_through.include?(through_item)
        )
      )

        unless middle_items_has_many.include? through_item
          middle_items_has_many << through_item
          source.children_has_many_through << target
          target.parents_has_many_through << source
          Association.check_middle_items_include(target)
        end
      else
        unless middle_items_has_one.include? through_item
          middle_items_has_one << through_item
          source.children_has_one_through << target
          target.parents_has_one_through << source
          Association.check_middle_items_include(target)
        end
      end
    
    end  
    
  end
  
  def self.set_middle_items
    associations = all.select(&:through?)

    associations.each do |association|
      association.set_middle_item
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
