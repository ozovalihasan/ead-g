require 'table_entity_base'
require 'attribute'
require 'association'
require 'active_support/core_ext/string'

class Table < TableEntityBase
  attr_accessor :name, :id, :twin_name, :attributes, :entities, :polymorphic, :polymorphic_names

  def initialize(table_id, tables)
    @id = table_id
    @name = tables[table_id]['name'].split(' || ')[0].underscore.singularize
    @entities = []
    @polymorphic = false
    @polymorphic_names = []
    @attributes = []
    tables[table_id]['attributes'].each do |(_attribute_id, attribute)|
      @attributes << Attribute.new(attribute)
    end
  end

  def model_name
    name.camelize
  end

  def add_references(entity)
    command = "bundle exec rails generate migration Add#{entity.name.camelize}RefTo#{name.camelize} #{entity.name}:references"

    system(command)
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

    @polymorphic_names = filtered_parent_names.find_all do |parent_name|
      belong_parents.find_all do |entity|
        entity.name == parent_name
      end.map(&:clone_parent).map(&:name).uniq.size > 1
    end
  end

  def check_polymorphic(command)
    update_polymorphic_names
    @polymorphic_names.each do |poly_name|
      add_polymorphic_reference(command, poly_name)
    end

    @polymorphic = true if @polymorphic_names.size.positive?
  end

  def create_model
    return if File.exist?("./app/models/#{name}.rb")

    command = 'bundle exec rails generate model '
    command << model_name
    attributes.each { |attribute| attribute.add_to(command) }

    check_polymorphic(command)

    system(command)
  end

  def add_reference_migration
    entities.each do |entity|
      (entity.parents_has_many + entity.parents_has_one).each do |parent|
        next if entity.one_polymorphic_names?(parent)

        add_references(parent)
      end
    end
  end
end
