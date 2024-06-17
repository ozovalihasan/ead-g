require 'table'

class Association
  attr_accessor :first_entity, :second_entity, :name,
                :through_entity, :optional, :reference_association, :middle_entity_checked, :have_issue

  alias optional? optional
  alias have_issue? have_issue

  @@groups_to_check_middle_entities = nil
  def initialize(edge)
    @middle_entity_checked = false

    @first_entity = Entity.find(edge['source']).reference_entity
    @second_entity = Entity.find(edge['target']).reference_entity
    @through_entity = nil
    @reference_association = self

    @middle_entities_has_one = []
    @middle_entities_has_many = []

    @first_entity.associations << self
    @second_entity.parent_associations << self

    @name = nil
    case edge['type']
    when 'hasMany'
      @first_entity.children_has_many << @second_entity
      @second_entity.parents_has_many << @first_entity

      @name = 'has_many'
      @optional = edge['data']['optional']
    when 'hasOne'
      @first_entity.children_has_one << @second_entity
      @second_entity.parents_has_one << @first_entity

      @name = 'has_one'
      @optional = edge['data']['optional']
    when 'through'
      @name = ':through'
      @through_entity = Entity.find(edge['data']['throughNodeId']).reference_entity
    end
  end

  def self.groups_to_check_middle_entities
    @@groups_to_check_middle_entities = {}
    Association.all_references.each do |reference_association|
      source = reference_association.first_entity.reference_entity
      target = reference_association.second_entity.reference_entity

      if reference_association.name == 'has_many' || reference_association.name == 'has_one'
        @@groups_to_check_middle_entities[[target.table, source.table, source.name]] = reference_association
      end
      @@groups_to_check_middle_entities[[source.table, target.table, target.name]] = reference_association
    end

    @@groups_to_check_middle_entities
  end

  def set_middle_entity
    return true unless through?
    return true if middle_entity_checked

    self.middle_entity_checked = true
    exist_an_issue = false
    source = first_entity
    target = second_entity

    first_part_of_association = @@groups_to_check_middle_entities[[source.table,
                                                                   through_entity.table,
                                                                   through_entity.name]]
    if first_part_of_association
      exist_an_issue = true unless first_part_of_association.set_middle_entity
    else
      exist_an_issue = true
    end

    last_part_of_association = @@groups_to_check_middle_entities[[through_entity.table,
                                                                  target.table,
                                                                  target.name]]
    if last_part_of_association
      exist_an_issue = true unless last_part_of_association.set_middle_entity
    else
      exist_an_issue = true
    end

    if exist_an_issue
      self.have_issue = true

      puts '----------------'
      puts "Association between #{first_entity.name} and #{second_entity.name} has issue"
      puts '----------------'

      return false
    end

    if (
        source.children_has_many.include?(through_entity) ||
        source.children_has_many_through.include?(through_entity)
      ) || (
        target.parents_has_many.include?(through_entity) ||
        target.parents_has_many_through.include?(through_entity)
      )
      source.children_has_many_through << target
      target.parents_has_many_through << source
    else
      source.children_has_one_through << target
      target.parents_has_one_through << source
    end
  end

  def self.clear_groups_to_check_middle_entities
    @@groups_to_check_middle_entities = nil
  end

  def self.set_all_middle_entities
    Association.groups_to_check_middle_entities
    Association.all_references.each(&:set_middle_entity)
    Association.clear_groups_to_check_middle_entities
  end

  def update_model_from_entity
    first_entity.update_model(second_entity, self)
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

  def self.all_references
    all.select { |association| association == association.reference_association }
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.dismiss_similar_ones
    similar_association_groups = all.group_by do |association|
      [association.first_entity, association.second_entity, association.through_entity, association.name]
    end
    similar_association_groups.values.each do |similar_associations|
      next if similar_associations.size == 1

      reference_association_of_group = similar_associations.find(&:optional?) || similar_associations.first
      similar_associations.each { |association| association.reference_association = reference_association_of_group }
    end
  end
end
