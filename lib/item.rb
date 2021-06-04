require 'item_base'
require 'attribute'
require 'association'
require 'active_support/core_ext/string'

class Item < ItemBase
  attr_accessor :attributes, :clones, :polymorphic, :polymorphic_names

  def initialize(block)
    super(block)
    @clones = []
    @polymorphic = false
    @polymorphic_names = []
    @attributes = []
    block.sub_blocks.each do |sub_block|
      add_to_attributes(sub_block)
    end
  end

  def add_to_attributes(block)
    @attributes << Attribute.new(block.content, block.type)
  end

  def model_name
    name.camelize
  end

  def add_references(command, item)
    return if command.include? " #{item.name}:references"

    command << " #{item.name}:references"
  end

  def add_polymorphic(command, poly_name)
    command << " #{poly_name}:references{polymorphic}"
  end

  def update_polymorphic_names
    return if clones.size.zero?

    belong_parents = []
    clones.each do |item|
      if item.through_association && item.parent_has_many?
        belong_parents << item.parent
        belong_parents << item.through_child
      elsif !item.parent_through_has_many? && item.parent
        belong_parents << item.parent
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
      add_polymorphic(command, poly_name)
    end

    @polymorphic = true if @polymorphic_names.size.positive?
  end

  def create_migration
    return if File.exist?("./app/models/#{name}.rb")

    command = 'bundle exec rails generate model '
    command << model_name
    attributes.each { |attribute| attribute.add_to(command) }

    check_polymorphic(command)

    clones.each do |item|
      add_references(command, item.through_child) if item.parent_has_many? && item.through_association

      next unless item.parent && !item.one_polymorphic_names?(item.parent) && (
        item.parent_has_any? || item.parent_through_has_one?
      )

      add_references(command, item.parent)
    end
    system(command)
  end
end
