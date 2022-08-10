require 'item_base'
require 'attribute'
require 'association'
require 'active_support/core_ext/string'

class Item < ItemBase
  
  attr_accessor :name, :id, :twin_name, :attributes, :clones, :polymorphic, :polymorphic_names

  def initialize(item_id, tables)
    @id = item_id
    @name = tables[item_id]["name"].split(' || ')[0].underscore.singularize
    @clones = []
    @polymorphic = false
    @polymorphic_names = []
    @attributes = []
    tables[item_id]["attributes"].each do |(attribute_id, attribute)|
      @attributes << Attribute.new(attribute)
    end
  end

  def model_name
    name.camelize
  end

  def add_references(command, item)
    return if command.include? " #{item.name}:references"

    command << " #{item.name}:references"
  end

  def add_polymorphic_reference(command, poly_name)
    command << " #{poly_name}:references{polymorphic}"
  end

  def update_polymorphic_names
    return if clones.size.zero?

    belong_parents = []
    clones.each do |item_clone|
      item_clone.parent_associations.each do |association|
        belong_parents << association.first_item
      end
    end

    belong_parent_names = belong_parents.map(&:name)

    filtered_parent_names = belong_parent_names.find_all do |parent_name|
      belong_parent_names.count(parent_name) > 1
    end.uniq

    @polymorphic_names = filtered_parent_names.find_all do |parent_name|
      belong_parents.find_all do |item|
        item.name == parent_name
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

    clones.each do |item_clone|
      # add_references(command, item_clone.through_child) if item_clone.parent_has_many? && item_clone.through_association
      
      (item_clone.parents_has_many + item_clone.parents_has_one).each do |parent|
        next if item_clone.one_polymorphic_names?(parent)
        parent.clone_parent.create_model
        add_references(command, parent)  
      end
      
    end
    system(command)
  end
end
