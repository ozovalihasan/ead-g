require 'table'

class Association
  attr_accessor :first_entity, :second_entity, :name, :middle_entities_has_one, :middle_entities_has_many, :through_entity

  def initialize(edge ) #first_entity, association_block)
    @first_entity = Entity.find(edge["source"])
    @second_entity = Entity.find(edge["target"])
    @through_entity = nil

    @middle_entities_has_one = []
    @middle_entities_has_many = []

    @first_entity.associations << self
    @second_entity.parent_associations << self

    @name = nil
    if edge["type"] === "hasMany" 
      @first_entity.children_has_many << @second_entity
      @second_entity.parents_has_many << @first_entity

      @name = "has_many"
    elsif edge["type"] === "hasOne" 
      @first_entity.children_has_one << @second_entity
      @second_entity.parents_has_one << @first_entity
      
      @name = "has_one"
    elsif edge["type"] === "through" 
      @first_entity.children_through << @second_entity
      @second_entity.parents_through << @first_entity

      @through_entity = Entity.find(edge["data"]["throughNodeId"])
      
      @name = ":through"
    end
  end

  def self.check_middle_entities_include(entity)
    associations = Association.all.select {|association| association.through_entity == entity }
    associations.each do |association| 
      unless ((association.middle_entities_has_many.include? entity ) || (association.middle_entities_has_one.include? entity ))
        association.set_middle_entity
      end
    end
  end

  def set_middle_entity
    source = first_entity
    target = second_entity
    
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
        ).include?(through_entity) 
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
        ).include?(through_entity) || (
          through_entity.parents_has_many.map(&:clone_parent).include?(target.clone_parent)  || 
          through_entity.parents_has_one.map(&:clone_parent).include?(target.clone_parent)
        )
      )
    )
      if (
        (
          source.children_has_many.include?(through_entity) || 
          source.children_has_many_through.include?(through_entity)
        ) || (
          target.parents_has_many.include?(through_entity) ||
          target.parents_has_many_through.include?(through_entity)
        )
      )

        unless middle_entities_has_many.include? through_entity
          middle_entities_has_many << through_entity
          source.children_has_many_through << target
          target.parents_has_many_through << source
          Association.check_middle_entities_include(target)
        end
      else
        unless middle_entities_has_one.include? through_entity
          middle_entities_has_one << through_entity
          source.children_has_one_through << target
          target.parents_has_one_through << source
          Association.check_middle_entities_include(target)
        end
      end
    
    end  
    
  end
  
  def self.set_middle_entities
    associations = all.select(&:through?)

    associations.each do |association|
      association.set_middle_entity
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
