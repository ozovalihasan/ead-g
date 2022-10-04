require 'table_entity_base'
require 'attribute'
require 'association'
require 'active_support/core_ext/string'

class Table < TableEntityBase
  attr_accessor :name, :id, :twin_name, :attributes, :entities, :polymorphic, :polymorphic_names, :superclass, :subclasses

  def initialize(table_id, table)
    @id = table_id
    @name = table['name'].underscore.singularize
    @entities = []
    @polymorphic = false
    @polymorphic_names = []
    @attributes = []
    table['attributes'].each do |(_attribute_id, attribute)|
      @attributes << Attribute.new(attribute)
    end
    @superclass = nil
    @subclasses = []
  end

  def self.update_superclasses(parsed_tables)
    all.each do |table|
      superclass_id = parsed_tables[table.id]["superclassId"]

      unless superclass_id == ""
        super_class = Table.find superclass_id
        table.superclass = super_class
        super_class.subclasses << table
      end

    end
  end

  def model_name
    name.camelize
  end

  def root_class
    nil unless @superclass 
    
    root = self
    
    while root.superclass
      root = root.superclass
    end

    root
  end

  def root_class?
    not superclass
  end

  def generate_reference_migration(name, polymorphic = false)
    command = "bundle exec rails generate migration Add#{name.camelize}RefTo#{root_class.name.camelize} #{name}:references"

    command << "{polymorphic}" if polymorphic

    system(command)
  end

  def add_polymorphic_reference_migration_for_sti
    if superclass && polymorphic
      polymorphic_names.each do |name|
        generate_reference_migration(name, true)  
      end
    end
  end

  def add_polymorphic_reference(command, poly_name)
    command << " #{poly_name}:references{polymorphic}"
  end

  def update_polymorphic_names
    return if entities.size.zero?

    belong_parents = []
    entities.each do |entity|
      entity.parent_associations.each do |association|
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
      end.map(&:clone_parent).map(&:name).uniq.size > 1
    end
  end

  def check_polymorphic(command)
    update_polymorphic_names
    polymorphic_names.each do |poly_name|
      add_polymorphic_reference(command, poly_name)
    end

    self.polymorphic = true if polymorphic_names.size.positive?
  end

  def create_model
    return if File.exist?("./app/models/#{name}.rb")

    command = "bundle exec rails generate model #{model_name}"

    if (subclasses.any?) && (root_class?)
      command << " type"
    end

    unless superclass
      attributes.each { |attribute| attribute.add_to(command) }
    end

    check_polymorphic(command)

    if superclass
      command << " --parent=#{superclass.name.classify}"
    end

    system(command)
  end

  def add_reference_migration
    entities.each do |entity|
      (entity.parents_has_many + entity.parents_has_one).each do |parent|
        next if entity.one_polymorphic_names?(parent)

        generate_reference_migration(parent.name)
      end
    end
  end
end
