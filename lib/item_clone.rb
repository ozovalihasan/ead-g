require 'item_base'
require 'association'
require 'project_file'

class ItemClone < ItemBase
  attr_accessor(:name, :id, :twin_name, :clone_parent, :parent, :parent_association, :associations, :parent_associations, 
  :parents_has_one, :parents_has_many, :parents_through, :children_has_one, :children_has_many, :children_through)

  def initialize(node, parent = nil, parent_association = nil)
    @id = node["id"]
    @name = node["data"]["name"].split(' || ')[0].underscore.singularize
    @twin_name = node["data"]["name"].split(' || ')[1]&.underscore&.singularize
    @clone_parent = Item.find(node["data"]["tableId"])
    @parent = parent
    @parent_association = parent_association
    
    @parent_associations = []
    @associations = []

    @parents_has_one = []
    @parents_has_many = []
    @parents_through = []

    @children_has_one = []
    @children_has_many = []
    @children_through = []
    # block.sub_blocks.each do |sub_block|
    #   add_to_associations(sub_block)
    # end
  end

  def model_name
    clone_parent.name.camelize
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
    clone_parent.name != name
  end

  def one_polymorphic_names?(item)
    real_item.polymorphic && real_item.polymorphic_names.include?(item.name)
  end

  def real_item
    clone_parent
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

      if !polymorphic_end && start_item.clone_name_different?
        end_model_line['class_name'] = "\"#{start_item.clone_parent.name.camelize}\""
        end_migration_line['foreign_key'] = "{ to_table: :#{start_item.clone_parent.name.pluralize} }"
      end
    end

    ProjectFile.update_line(real_item.name, 'model', /belongs_to :#{start_item.name}/, end_model_line)

    migration_name = real_item.name
    ProjectFile.update_line(migration_name, 'migration', /t.references :#{start_item.name}/, end_migration_line)
  end

  def update_start_model_file(end_item, association, intermediate_item = nil)
    start_model = real_item.name

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

    line_content = {}
    line_content[association.name] = if intermediate_item&.one_polymorphic_names?(end_item) && association.has_many?
                                       ":#{end_item.real_item.name.pluralize}"
                                     else
                                       ":#{end_model}"
                                     end

    if intermediate_item
      line_content['through'] = ":#{intermediate_model}"
      if intermediate_item.one_polymorphic_names?(end_item)
        line_content['source'] = ":#{end_item.name}"
        line_content['source_type'] = "\"#{end_item.real_item.name.camelize}\" "
      end
    elsif !intermediate_item
      line_content['class_name'] = "\"#{end_item.real_item.name.camelize}\"" if end_item.clone_name_different?

      if end_item.one_polymorphic_names?(self)
        line_content['as'] = ":#{name}"
      elsif clone_name_different?
        line_content['foreign_key'] = "\"#{name.singularize}_id\""
      end
    end

    ProjectFile.add_line(start_model, end_model, line_content)
  end

  def update_model(end_item, association, intermediate_item = nil)
    return unless association.has_one? || association.has_many?

    end_item.update_end_model_migration_files(self, association) unless intermediate_item
    update_start_model_file(end_item, association, intermediate_item)
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
end
