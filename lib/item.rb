require 'item_base'
require 'attribute'
require 'association'
require 'active_support/core_ext/string'

class Item < ItemBase
  attr_accessor :clones, :polymorphic, :polymorphic_names

  def initialize(block, parent = nil, parent_association = nil)
    super(block, parent, parent_association)
    @clones = []
    @polymorphic = false
    @polymorphic_names = []
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
    all_parents_name = [self, *clones].map do |item|
      [item.parent&.name, item.through_association && item.through_child.name]
    end
    all_parents_name.flatten!.compact!
    @polymorphic_names = all_parents_name.find_all { |name| all_parents_name.count(name) > 1 }.uniq
  end

  def check_polymorphic(_command)
    update_polymorphic_names
    @polymorphic = true if @polymorphic_names.size.positive?
  end

  def create_migration
    return if File.exist?("./app/models/#{name}.rb")

    command = 'bundle exec rails generate model '
    command << model_name
    attributes.each { |attribute| attribute.add_to(command) }

    check_polymorphic(command)

    @polymorphic_names.each do |poly_name|
      add_polymorphic(command, poly_name)
    end

    [self, *clones].each do |item|
      if item.parent_has_many? && item.through_association
        item.through_child.create_migration if item.through_child.not_clone?
        add_references(command, item.through_child)
      end

      next unless item.parent && !item.one_polymorphic_names?(item.parent) && (
        item.parent_has_any? || item.parent_through_has_one?
      )

      add_references(command, item.parent)
    end
    system(command)
  end
end
