require 'item_base'
require 'association'
require 'project_file'

class ItemClone < ItemBase
  attr_accessor(:name, :id, :twin_name, :clone_parent, :parent, :parent_association, :associations, :parent_associations, 
  :parents_has_one, :parents_has_many, :parents_through, :children_has_one, :children_has_many, :children_through,
  :children_has_one_through, :children_has_many_through, :parents_has_one_through, :parents_has_many_through)

  def initialize(node)
    @id = node["id"]
    @name = node["data"]["name"].split(' || ')[0].underscore.singularize
    @twin_name = node["data"]["name"].split(' || ')[1]&.underscore&.singularize
    @clone_parent = Item.find(node["data"]["tableId"])
    
    @parent_associations = []
    @associations = []

    @parents_has_one = []
    @parents_has_many = []
    @parents_has_one_through = []
    @parents_has_many_through = []
    @parents_through = []

    @children_has_one = []
    @children_has_many = []
    @children_has_one_through = []
    @children_has_many_through = []
    @children_through = []
  end

  def model_name
    clone_parent.name.camelize
  end

  def reals_same?(item)
    real_item == item.real_item
  end

  def self.find_by_name(name)
    all.find {|item_clone| item_clone.name == name}
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

  def update_end_model_migration_files(start_item, association)
    polymorphic_end = one_polymorphic_names?(start_item)
    
    return if polymorphic_end

    end_model_line = {}
    end_migration_line = {}
    
    if association.has_any?
      end_model_line['belongs_to'] = ":#{start_item.name}"
      
      if reals_same?(start_item)
        end_model_line['optional'] = 'true'
        end_migration_line['null'] = 'true'
      end

      if !polymorphic_end && start_item.clone_name_different?
        end_model_line['class_name'] = "\"#{start_item.clone_parent.name.camelize}\""
        end_migration_line['foreign_key'] = "{ to_table: :#{start_item.clone_parent.name.pluralize} }"
      end
    end

    unless end_model_line.empty?
      ProjectFile.add_belong_line(self.clone_parent.name, end_model_line)
    end

    unless end_migration_line.empty?
      migration_name = "Add#{start_item.name.camelize}RefTo#{clone_parent.name.camelize}".underscore

      ProjectFile.update_line(migration_name, 'reference_migration', /add_reference :#{clone_parent.name.pluralize}/, end_migration_line)
    end
  end

  def update_start_model_file(end_item, association)
    start_model = real_item.name

    end_model = end_item.name
    intermediate_item = association.through_item

    intermediate_model = intermediate_item.name if intermediate_item

    if association.has_many? || (self.children_has_many_through.include? end_item)
      end_model = end_model.pluralize
      intermediate_model = intermediate_model.pluralize if intermediate_model
    end

    line_content = {}

    if association.has_many? || (self.children_has_many_through.include? end_item)
      line_content["has_many"] = if intermediate_item&.one_polymorphic_names?(end_item) && (association.has_many? || (self.children_has_many_through.include? end_item))
        ":#{end_item.real_item.name.pluralize}"
      else
        ":#{end_model}"
      end
    end

    if association.has_one? || (self.children_has_one_through.include? end_item)
      line_content["has_one"] = if intermediate_item&.one_polymorphic_names?(end_item) && (association.has_one? || (self.children_has_one_through.include? end_item))
        ":#{end_item.real_item.name}"
      else
        ":#{end_model}"
      end
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

  def update_model(end_item, association)
    if association.has_any?
      end_item.update_end_model_migration_files(self, association)
    end
    
    update_start_model_file(end_item, association)
  end

end
