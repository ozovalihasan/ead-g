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

  def grand
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

  def grand_association
    parent.parent_association
  end

  def grand_has_many?
    grand_association&.has_many?
  end

  def grand_has_one?
    grand_association&.has_one?
  end

  def grand_real_self?
    real_item == grand.real_item
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

  def parent_has_any?
    parent_has_one? || parent_has_many?
  end

  def parent_through_has_one?
    parent_through? && grand_has_one?
  end

  def parent_through_has_many?
    parent_through? && grand_has_many
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.find(id)
    all.find { |item| item.id == id }
  end

  def through_association
    associations.find(&:through?)
  end

  def through_child
    through_association.second_items.first
  end

  def through?(item)
    item.present?
  end

  def open_close_file(tempfile_name, file_name, &block)
    tempfile = File.open(tempfile_name, 'w')
    file = File.new(file_name)

    block.call(file, tempfile)

    file.close
    tempfile.close

    FileUtils.mv(
      tempfile_name,
      file_name
    )
  end

  def open_migration_file(model_migration_name, &block)
    tempfile_name = './db/migrate/migration_update.rb'
    file_name = Dir["./db/migrate/*_#{model_migration_name.pluralize}.rb"].first

    open_close_file(tempfile_name, file_name) do |file, tempfile|
      block.call(file, tempfile)
    end
  end

  def open_model_file(model, &block)
    tempfile_name = './app/models/model_update.rb'
    file_name = "./app/models/#{model}.rb"

    open_close_file(tempfile_name, file_name) do |file, tempfile|
      block.call(file, tempfile)
    end
  end

  def clone_name_different?
    clone? && (clone_parent.name != start_item.name)
  end

  def update_model(start_item, end_item, association, intermediate_item = nil, polymorphic = false)
    start_model = start_item.real_item.name
    return unless association.has_one? || association.has_many?

    if start_item.clone? && !polymorphic
      open_model_file(end_item.real_item.name) do |file, tempfile|
        file.each do |line|
          if line.include? "belongs_to :#{start_item.name}"

            line = "  belongs_to :#{start_item.name}, class_name: \"#{start_item.clone_parent.name.capitalize}\""
            line << if end_item.real_item == start_item.real_item
                      ", optional: true \n"
                    else
                      ", foreign_key: \"#{start_item.name}_id\"\n"
                    end
          end
          tempfile << line
        end
      end

      migration_name = end_item.real_item.name
      open_migration_file(migration_name) do |file, tempfile|
        file.each do |line|
          if line.include? "t.references :#{start_item.name}, null: false, foreign_key: true"
            line = "      t.references :#{start_item.name}, null: #{end_item.real_item == start_item.real_item}, foreign_key: { to_table: :#{start_item.clone_parent.name.pluralize} }\n"
          end
          tempfile << line
        end
      end

    end

    end_model = end_item.name
    poly_as = start_item.name
    intermediate_model = intermediate_item.name if intermediate_item

    if association.has_many?
      end_model = end_model.pluralize
      intermediate_model = intermediate_model.pluralize if intermediate_model
    end

    open_model_file(start_model) do |file, tempfile|
      file.each do |line|
        if line.include? 'end'
          line_association = "  #{association.name} :#{end_model}"
          if end_item.clone_name_different?
            line_association << ", class_name: \"#{end_item.clone_parent.name.capitalize}\""
          end

          if end_item.polymorphic
            line_association << ", as: :#{poly_as}"
          elsif start_item.clone_name_different?
            line_association << ", foreign_key: \"#{start_item.name.singularize}_id\""
          end
          line_association << ", through: :#{intermediate_model}" if through?(intermediate_item)
          line_association << "\n"
          tempfile << line_association
        end
        tempfile << line
      end
    end
  end

  def add_associations_to_model
    if parent_through_has_many?
      if grand_real_self?
        update_model(grand, self, grand_association, parent)
      else
        update_model(self, parent, grand_association)
        update_model(grand, self, grand_association, parent)
        update_model(self, grand, grand_association, parent)
      end
    elsif parent_through_has_one?
      # if grand_real_self?

      # else
      # end
      update_model(parent, self, grand_association)
      update_model(grand, self, grand_association, parent)
    end

    associations.each do |association|
      next unless association.has_any?

      association.second_items.each do |second_item|
        if second_item.real_item.polymorphic && (second_item.real_item.polymorphic_names.include? name)
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
    !clone?
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

  def add_references(command, item)
    command << " #{item.name}:references"
  end

  def add_polymorphic(command, poly_name)
    command << " #{poly_name}:references{polymorphic}"
  end

  def update_polymorphic_names
    all_parents_name = [self, *clones].map do |item|
      item.parent&.name
    end
    all_parents_name.compact!
    @polymorphic_names = all_parents_name.find_all { |name| all_parents_name.count(name) > 1 }.uniq
  end

  def check_polymorphic(command)
    update_polymorphic_names
    @polymorphic = true if @polymorphic_names.size.positive?

    [self, *clones].each do |item|
      next unless item.parent && !@polymorphic_names.include?(item.parent.name) && (
        item.parent_has_any? || item.parent_through_has_one?
      )

      add_references(command, item)
    end
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
