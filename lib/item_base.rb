require 'project_file'

class ItemBase
  attr_accessor :name, :parent, :parent_association, :associations, :attributes, :id, :twin_name

  def initialize(block, parent = nil, parent_association = nil)
    @id = block.id
    @name = block.content.split(' || ')[0].underscore.singularize
    @twin_name = block.content.split(' || ')[1]&.underscore&.singularize
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

  def grand
    parent.parent
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

  def grand_real_self_real?
    reals_same? grand
  end

  def reals_same?(item)
    real_item == item.real_item
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
    parent_through? && grand_has_many?
  end

  def through_association
    associations.find(&:through?)
  end

  def through_child
    through_association&.second_items&.first
  end

  def through?(item)
    item.present?
  end

  def clone_name_different?
    clone? && (clone_parent.name != name)
  end

  def one_polymorphic_names?(item)
    real_item.polymorphic && real_item.polymorphic_names.include?(item.name)
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

  def grand_many_through_reals_same?(item)
    parent_through_has_many? && (grand == item) && reals_same?(item)
  end

  def parent_has_many_reals_same_through_child?(item)
    item.parent_through_has_many? && (through_child == item) && item.reals_same?(parent)
  end

  def update_end_model_migration_files(start_item, association)
    polymorphic_end = one_polymorphic_names?(start_item)

    end_model_line = {}
    end_migration_line = {}
    if association.has_one? && start_item.parent&.reals_same?(self)
      end_model_line['optional'] = 'true'
      end_migration_line['null'] = 'true'
    end

    if association.has_any?
      if reals_same?(start_item)
        end_model_line['optional'] = 'true'
        end_migration_line['null'] = 'true'
      end

      if start_item.clone? && !polymorphic_end && start_item.clone_name_different?
        end_model_line['class_name'] = "\"#{start_item.clone_parent.name.camelize}\""
        end_migration_line['foreign_key'] = "{ to_table: :#{start_item.clone_parent.name.pluralize} }"
      end
    end

    ProjectFile.update_line(real_item.name, 'model', /belongs_to :#{start_item.name}/, end_model_line)

    migration_name = real_item.name
    ProjectFile.update_line(migration_name, 'migration', /t.references :#{start_item.name}/, end_migration_line)
  end

  def update_model(end_item, association, intermediate_item = nil)
    start_model = real_item.name

    return unless association.has_one? || association.has_many?

    end_item.update_end_model_migration_files(self, association) unless intermediate_item

    end_model = if end_item.parent_has_many_reals_same_through_child?(self)
                  end_item.twin_name
                else
                  end_item.name
                end

    intermediate_model = if grand_many_through_reals_same?(end_item)
                           intermediate_item.twin_name
                         elsif intermediate_item
                           intermediate_item.name
                         end

    if association.has_many?
      end_model = end_model.pluralize
      intermediate_model = intermediate_model.pluralize if intermediate_model
    end

    start_model_file = {}
    start_model_file[association.name] = if intermediate_item&.one_polymorphic_names?(end_item) && association.has_many?
                                           ":#{end_item.real_item.name.pluralize}"
                                         else
                                           ":#{end_model}"
                                         end

    if intermediate_item
      start_model_file['through'] = ":#{intermediate_model}"
      if intermediate_item.one_polymorphic_names?(end_item)
        start_model_file['source'] = ":#{end_item.name}"
        start_model_file['source_type'] = "\"#{end_item.real_item.name.camelize}\" "
      end
    elsif !intermediate_item
      start_model_file['class_name'] = "\"#{end_item.real_item.name.camelize}\"" if end_item.clone_name_different?

      if end_item.one_polymorphic_names?(self)
        start_model_file['as'] = ":#{name}"
      elsif clone_name_different?
        start_model_file['foreign_key'] = "\"#{name.singularize}_id\""
      end
    end

    ProjectFile.add_line(start_model, 'model', end_model, start_model_file)
  end

  def parent_through_add_associations
    if parent_through_has_many?
      update_model(parent, grand_association)
      update_model(grand, grand_association, parent)

    elsif parent_through_has_one?
      parent.update_model(self, grand_association)
    end

    grand.update_model(self, grand_association, parent)
  end

  def add_associations
    parent_through_add_associations if parent_through?

    associations.each do |association|
      next unless association.has_any?

      association.second_items.each do |second_item|
        update_model(second_item, association)
      end
    end
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.find(id)
    all.find { |item| item.id == id }
  end
end
