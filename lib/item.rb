require 'attribute'
require 'association'
require 'fileutils'
require 'active_support/core_ext/string'

class Item
  attr_accessor :name, :parent, :parent_association, :associations, :attributes

  def initialize(block, parent = nil, parent_association = nil)
    @name = block.content.downcase.singularize
    @parent = parent
    @parent_association = parent_association
    @attributes = []
    @associations = []

    block.sub_blocks.each do |sub_block|
      if sub_block.attribute
        add_to_attributes(sub_block)
      elsif sub_block.attribute_container
        add_attribute_container(sub_block)
      elsif sub_block.association
        add_to_associations(sub_block)
      end
    end
  end

  def grand_parent
    parent.parent
  end

  def add_attribute_container(block)
    block.sub_blocks.each do |attribute|
      add_to_attributes(attribute)
    end
  end

  def add_to_attributes(block)
    @attributes << Attribute.new(block.content, block.type)
  end

  def add_to_associations(block)
    @associations << Association.new(self, block)
  end

  def grand_parent_association
    parent.parent_association
  end

  def grand_parent_has_many?
    grand_parent_association&.has_many?
  end

  def grand_parent_has_one?
    grand_parent_association&.has_one?
  end

  def parent_through?
    parent_association&.through?
  end

  def parent_has_many?
    parent_association&.has_many?
  end

  def parent_has_one?
    parent_association&.has_one?
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def through_association
    associations.find { |association| association.through? }
  end

  def through_child
    through_association.second_items.first
  end

  def model_name
    name.capitalize
  end

  def create_migration
    def add_references(command, item)
      command << " #{item.name}:references"
    end

    return if File.exist?("./app/models/#{name}.rb")

    command = 'bundle exec rails generate model '
    command << model_name
    attributes.each { |attribute| attribute.add_to(command) }

    if parent_has_many? || parent_has_one?
      add_references(command, parent)
    elsif parent_through? && grand_parent_has_one?
      add_references(command, parent)
    end

    if parent_has_many? && through_association
      through_child.create_migration
      add_references(command, through_child)
    end

    system(command)
  end

  def add_associations_to_model
    def through?(item)
      item.present?
    end

    def update_model(start_item, end_item, association, intermediate_item = nil)
      return unless association.has_one? || association.has_many?

      start_model = start_item.name
      end_model = end_item.name
      intermediate_model = intermediate_item.name if intermediate_item

      if association.has_many?
        end_model = end_model.pluralize
        intermediate_model = intermediate_model.pluralize if intermediate_model
      end

      tempfile = File.open('./app/models/model_update.rb', 'w')
      f = File.new("./app/models/#{start_model}.rb")
      f.each do |line|
        if line.include? 'end'
          line_association = "  #{association.name} :#{end_model}"
          line_association << ", through: :#{intermediate_model}" if through?(intermediate_item)
          line_association << "\n"
          tempfile << line_association
        end
        tempfile << line
      end
      f.close
      tempfile.close

      FileUtils.mv(
        './app/models/model_update.rb',
        "./app/models/#{start_model}.rb"
      )
    end

    if parent_through?
      if grand_parent_has_many?
        update_model(self, parent, grand_parent_association)
        update_model(grand_parent, self, grand_parent_association, parent)
        update_model(self, grand_parent, grand_parent_association, parent)

      elsif grand_parent_has_one?
        update_model(parent, self, grand_parent_association)
        update_model(grand_parent, self, grand_parent_association, parent)
      end
    end
    associations.each do |association|
      next unless association.has_many? || association.has_one?

      association.second_items.each do |second_item|
        update_model(self, second_item, association)
      end
    end
  end
end
