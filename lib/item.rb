require 'attribute'
require 'association'
require 'fileutils'
require 'active_support/core_ext/string'

class ItemBase
  attr_accessor :name, :parent, :parent_association, :associations, :attributes, :id

  def initialize(block, parent = nil, parent_association = nil)
    @id = block.id
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

  def self.find(id)
    all.find { |item| item.id == id }
  end

  def through_association
    associations.find { |association| association.through? }
  end

  def through_child
    through_association.second_items.first
  end

  def add_associations_to_model
    def through?(item)
      item.present?
    end

    def open_migration_file(model_migration_name, &block)
      tempfile = File.open('./db/migrate/migration_update.rb', 'w')
      file_name = Dir["./db/migrate/*_#{model_migration_name.pluralize}.rb"].first
      file = File.new(file_name)

      block.call(file, tempfile)

      file.close
      tempfile.close

      FileUtils.mv(
        './db/migrate/migration_update.rb',
        file_name
      )
    end

    def open_model_file(model, &block)
      tempfile = File.open('./app/models/model_update.rb', 'w')
      file = File.new("./app/models/#{model}.rb")

      block.call(file, tempfile)

      file.close
      tempfile.close

      FileUtils.mv(
        './app/models/model_update.rb',
        "./app/models/#{model}.rb"
      )
    end

    def update_model(start_item, end_item, association, intermediate_item = nil, polymorphic = false)
      start_model = start_item.not_clone? ? start_item.name : start_item.clone_parent.name
      return unless association.has_one? || association.has_many?

      end_model = end_item.name
      poly_as = start_item.name
      intermediate_model = intermediate_item.name if intermediate_item

      if start_item.clone? && !polymorphic
        open_model_file(end_item.clone_parent.name) do |file, tempfile|
          file.each do |line|
            if line.include? "belongs_to :#{start_item.name}"
              line = "  belongs_to :#{start_item.name}, class_name: \"#{start_item.clone_parent.name.capitalize}\", foreign_key: \"#{start_item.name}_id\"\n"
            end
            tempfile << line
          end
        end

        migration_name = end_item.clone? ? end_item.clone_parent.name : end_item.name
        open_migration_file(migration_name) do |file, tempfile|
          file.each do |line|
            if line.include? "t.references :#{start_item.name}, null: false, foreign_key: true"
              line = "      t.references :#{start_item.name}, null: false, foreign_key: { to_table: :#{start_item.clone_parent.name.pluralize}}\n"
            end
            tempfile << line
          end
        end

      end

      if association.has_many?
        end_model = end_model.pluralize
        intermediate_model = intermediate_model.pluralize if intermediate_model
      end

      open_model_file(start_model) do |file, tempfile|
        file.each do |line|
          if line.include? 'end'
            line_association = "  #{association.name} :#{end_model}"
            if end_item.clone? && (end_item.clone_parent.name != end_model.singularize)
              line_association << ", class_name: \"#{end_item.clone_parent.name.capitalize}\""
            end
            if start_item.clone? && (start_item.clone_parent.name != start_item.name) && !polymorphic
              line_association << ", foreign_key: \"#{start_item.name.singularize}_id\""
            end
            line_association << ", as: :#{poly_as}" if polymorphic
            line_association << ", through: :#{intermediate_model}" if through?(intermediate_item)
            line_association << "\n"
            tempfile << line_association
          end
          tempfile << line
        end
      end
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
        if second_item.not_clone? && second_item.polymorphic && (second_item.polymorphic_names.include? name)
          update_model(self, second_item, association, nil, true)
        elsif second_item.clone? && second_item.clone_parent.polymorphic && (second_item.clone_parent.polymorphic_names.include? name)
          update_model(self, second_item, association, nil, true)
        else
          update_model(self, second_item, association)
        end
      end
    end
  end

  def clone?
    instance_of?(ItemClone)
  end

  def not_clone?
    instance_of?(Item)
  end

  def real_item
    clone? ? clone_parent : self
  end
end

class Item < ItemBase
  attr_accessor :clones, :polymorphic, :polymorphic_names

  def initialize(block, parent = nil, parent_association = nil)
    super(block, parent, parent_association)
    @clones = []
    @polymorphic = false
    @polymorphic_names = []
  end

  def model_name
    name.capitalize
  end

  def all_parent_has_many?
    parent_association&.has_many?
  end

  def create_migration
    def add_references(command, item)
      command << " #{item.name}:references"
    end

    def add_polymorphic(command, poly_name)
      command << " #{poly_name}:references{polymorphic}"
    end
    return if File.exist?("./app/models/#{name}.rb")

    command = 'bundle exec rails generate model '
    command << model_name
    attributes.each { |attribute| attribute.add_to(command) }

    all_parents_name = [self, *clones].map do |item|
      item.parent.name if item.parent
    end

    all_parents_name.compact!
    @polymorphic_names = all_parents_name.find_all { |name| all_parents_name.count(name) > 1 }.uniq
    @polymorphic = true if @polymorphic_names.size > 0

    [self, *clones].each do |item|
      if item.parent && !@polymorphic_names.include?(item.parent.name)
        if item.parent_has_many? || item.parent_has_one?
          add_references(command, item.parent)
        elsif item.parent_through? && item.grand_parent_has_one?
          add_references(command, item.parent)
        end
      end
    end

    @polymorphic_names.each do |poly_name|
      add_polymorphic(command, poly_name)
    end

    if parent_has_many? && through_association
      through_child.create_migration if through_child.not_clone?
      add_references(command, through_child)
    end

    system(command)
  end
end

class ItemClone < ItemBase
  attr_accessor :clone_parent

  def initialize(block, parent = nil, parent_association = nil)
    super(block, parent, parent_association)
    @clone_parent = block.clone_parent
  end

  def model_name
    clone_parent.name.capitalize
  end
end
