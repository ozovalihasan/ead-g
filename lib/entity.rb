require 'table_entity_base'
require 'association'
require 'project_file'

class Entity < TableEntityBase
  attr_accessor(:name, :id, :table, :parent, :parent_association, :associations, :parent_associations,
                :parents_has_one, :parents_has_many, :parents_through, :children_has_one, :children_has_many, :children_through,
                :children_has_one_through, :children_has_many_through, :parents_has_one_through, :parents_has_many_through)

  def initialize(node)
    @id = node['id']
    @name = node['data']['name'].underscore.singularize
    @table = Table.find(node['data']['tableId'])
    @table.entities << self

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

  def self.find_by_name(name)
    all.find { |entity| entity.name == name }
  end

  def model_name
    table.name.camelize
  end

  def root_classes_same?(entity)
    table.root_class == entity.table.root_class
  end

  def table_name_different?
    table.name != name
  end

  def root_class_name_different?
    table.root_class.name != name
  end

  def one_polymorphic_names?(entity)
    table.polymorphic && table.polymorphic_names.include?(entity.name)
  end

  def update_end_model_migration_files(start_entity, association)
    return unless association.has_any?

    end_model_line = {}
    end_migration_line = {}

    end_model_line['belongs_to'] = ":#{start_entity.name}"

    if root_classes_same?(start_entity)
      end_model_line['optional'] = 'true'
      end_migration_line['null'] = 'true'
    else
      end_migration_line['null'] = 'false'
    end

    end_migration_line['null'] = 'true' unless table.root_class?

    polymorphic_end = one_polymorphic_names?(start_entity)

    unless polymorphic_end
      end_model_line['class_name'] = "\"#{start_entity.table.name.camelize}\"" if start_entity.table_name_different?

      if start_entity.root_class_name_different?
        end_migration_line['foreign_key'] = "{ to_table: :#{start_entity.table.root_class.name.pluralize} }"
      end

      if start_entity.table.superclass && start_entity.root_class_name_different?
        end_migration_line['column'] = ":#{start_entity.name}_id"
      end

    end

    update_project_files(start_entity, end_model_line, end_migration_line)
  end

  def update_project_files(start_entity, end_model_line, end_migration_line)
    update_model_files(start_entity, end_model_line)
    update_migration_files(start_entity, end_migration_line)
  end

  def update_model_files(start_entity, end_model_line)
    return if end_model_line.empty?

    polymorphic_end = one_polymorphic_names?(start_entity)

    if polymorphic_end
      ProjectFile.update_line(table.name, 'model', /belongs_to :#{start_entity.name}/, end_model_line)
    else
      ProjectFile.add_belong_line(table.name, end_model_line)
    end
  end

  def update_migration_files(start_entity, end_migration_line)
    return if end_migration_line.empty?

    polymorphic_end = one_polymorphic_names?(start_entity)

    if table.root_class? && polymorphic_end
      migration_name = "Create#{table.name.camelize.pluralize}".underscore

      ProjectFile.update_line(
        migration_name,
        'migration',
        /t.references :#{start_entity.name}/,
        end_migration_line
      )

    else
      migration_name = "Add#{start_entity.name.camelize}RefTo#{table.root_class.name.camelize}".underscore

      ProjectFile.update_line(
        migration_name,
        'reference_migration',
        /add_reference :#{table.root_class.name.pluralize}/,
        end_migration_line
      )
    end
  end

  def update_start_model_file(end_entity, association)
    start_model = table.name

    end_model = end_entity.name
    intermediate_entity = association.through_entity

    intermediate_model = intermediate_entity.name if intermediate_entity

    if association.has_many? || (children_has_many_through.include? end_entity)
      end_model = end_model.pluralize
      intermediate_model = intermediate_model.pluralize if intermediate_model
    end

    line_content = {}

    if association.has_many? || (children_has_many_through.include? end_entity)
      line_content['has_many'] = if intermediate_entity&.one_polymorphic_names?(end_entity) && (children_has_many_through.include? end_entity)
                                   ":#{end_entity.table.name.pluralize}"
                                 else
                                   ":#{end_model}"
                                 end
    end

    if association.has_one? || (children_has_one_through.include? end_entity)
      line_content['has_one'] = if intermediate_entity&.one_polymorphic_names?(end_entity) && (children_has_one_through.include? end_entity)
                                  ":#{end_entity.table.name}"
                                else
                                  ":#{end_model}"
                                end
    end

    if intermediate_entity
      line_content['through'] = ":#{intermediate_model}"
      if intermediate_entity.one_polymorphic_names?(end_entity)
        line_content['source'] = ":#{end_entity.name}"
        line_content['source_type'] = "\"#{end_entity.table.name.camelize}\" "
      end
    elsif !intermediate_entity
      line_content['class_name'] = "\"#{end_entity.table.name.camelize}\"" if end_entity.table_name_different?

      if end_entity.one_polymorphic_names?(self)
        line_content['as'] = ":#{name}"
      elsif table_name_different?
        line_content['foreign_key'] = "\"#{name.singularize}_id\""
      end
    end

    ProjectFile.add_line(start_model, end_model, line_content)
  end

  def update_model(end_entity, association)
    end_entity.update_end_model_migration_files(self, association) if association.has_any?

    update_start_model_file(end_entity, association)
  end
end
