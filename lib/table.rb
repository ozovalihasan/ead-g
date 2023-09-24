require 'table_entity_base'
require 'attribute'
require 'association'
require 'active_support/core_ext/string'

class Table < TableEntityBase
  attr_accessor :name, :id, :attributes, :entities, :polymorphic, :polymorphic_names, :superclass, :subclasses

  def initialize(table_id, table)
    @id = table_id
    @name = table['name'].underscore.singularize
    @entities = []
    @polymorphic = false
    @polymorphic_names = {}
    @attributes = []
    table['attributes'].each do |(_attribute_id, attribute)|
      @attributes << Attribute.new(attribute)
    end
    @superclass = nil
    @subclasses = []
  end

  def self.update_superclasses(parsed_tables)
    all.each do |table|
      superclass_id = parsed_tables[table.id]['superclassId']

      next if superclass_id == ''

      super_class = Table.find superclass_id
      table.superclass = super_class
      super_class.subclasses << table
    end
  end

  def model_name
    name.camelize
  end

  def root_class
    nil unless @superclass

    root = self

    root = root.superclass while root.superclass

    root
  end

  def root_class?
    !superclass
  end

  def generate_reference_migration(name, polymorphic = false)
    command = "bundle exec rails generate migration Add#{name.camelize}RefTo#{root_class.name.camelize} #{name}:belongs_to"

    command << '{polymorphic}' if polymorphic

    system(command)
  end

  def set_polymorphic_names
    return if entities.empty?

    belong_parents = []
    entities.each do |entity|
      entity.parent_associations.select(&:has_any?).each do |association|
        belong_parents << association.first_entity
      end
    end

    belong_parent_names = belong_parents.map(&:name)

    filtered_parent_names = belong_parent_names.find_all do |parent_name|
                              belong_parent_names.count(parent_name) > 1
                            end.uniq

    self.polymorphic_names = filtered_parent_names.find_all do |parent_name|
                               belong_parents.find_all do |entity|
                                 entity.name == parent_name
                               end.map(&:table).map(&:name).uniq.size > 1
                             end 
                             .map {|polymorphic_name| [polymorphic_name, nil]}.to_h

    find_associations_related_to = lambda do |polymorphic_name|
      entities.map do |entity| 
        entity.parent_associations.select {|association| has_any? && (association.first_entity.name == polymorphic_name)}
      end.flatten
    end

    self.polymorphic_names = polymorphic_names.map do |polymorphic_name, _|
                               [
                                 polymorphic_name, 
                                 {
                                   associations: find_associations_related_to.call(polymorphic_name),
                                   checked: false
                                 }
                               ]
                             end.to_h
    
    self.polymorphic = true if polymorphic_names.size.positive?
  end

  def create_model
    return if File.exist?("./app/models/#{name}.rb")

    command = "bundle exec rails generate model #{model_name}"

    command << ' type' if subclasses.any? && root_class?

    attributes.each { |attribute| attribute.add_to(command) } unless superclass

    command << " --parent=#{superclass.name.classify}" if superclass

    system(command)
  end

  def add_reference_migration
    entities.each do |entity|
      parent_entities = entity.parents_has_many + entity.parents_has_one
      
      parent_entities.uniq(&:name).each do |parent|
        generate_reference_migration(parent.name, entity.one_polymorphic_names?(parent))
      end
    end
  end
end
