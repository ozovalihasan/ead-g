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
    clone? && (clone_parent.name != name)
  end

  def change_file_line(file, tempfile, keywords, line_content)
    file.each do |line|
      if line.match(keywords)
        line.gsub!("\n", ' ')
        line_content.each do |key, value|
          if line.include? key
            line.gsub!(/#{key}: .*([, ])/, "#{key}: #{value}#{Regexp.last_match(1)}")
          else
            line << ", #{key}: #{value}"
          end
        end
        line << "\n"

      end
      tempfile << line
    end
  end

  def update_model(start_item, end_item, association, intermediate_item = nil, polymorphic_end = false, polymorphic_intermediate = false)
    start_model = start_item.real_item.name

    return unless association.has_one? || association.has_many?

    start_model_file = {}
    end_model_line = {}
    end_migration_line = {}

    unless intermediate_item
      if association.has_one? && start_item.parent&.reals_same?(end_item)
        end_model_line['optional'] = 'true'
        end_migration_line['null'] = 'true'
      end

      if association.has_any?
        if end_item.reals_same?(start_item)
          end_model_line['optional'] = 'true'
          end_migration_line['null'] = 'true'
        end

        if start_item.clone? && !polymorphic_end && start_item.clone_name_different?
          end_model_line['class_name'] = "\"#{start_item.clone_parent.name.camelize}\""
          end_migration_line['foreign_key'] = "{ to_table: :#{start_item.clone_parent.name.pluralize} }"
        end
      end

      open_model_file(end_item.real_item.name) do |file, tempfile|
        change_file_line(file, tempfile, /belongs_to :#{start_item.name}/, end_model_line)
      end

      migration_name = end_item.real_item.name
      open_migration_file(migration_name) do |file, tempfile|
        change_file_line(file, tempfile, /t.references :#{start_item.name}/, end_migration_line)
      end
    end

    end_model = if start_item.parent_through_has_many? && !intermediate_item && (start_item == end_item.through_child) && start_item.reals_same?(end_item.parent)
                  end_item.twin_name
                else
                  end_item.name
                end

    intermediate_model = if intermediate_item && start_item.parent_through_has_many? && (start_item == intermediate_item.through_child) && start_item.reals_same?(end_item)
                           intermediate_item.twin_name
                         elsif intermediate_item
                           intermediate_item.name
                         end

    if association.has_many?
      end_model = end_model.pluralize
      intermediate_model = intermediate_model.pluralize if intermediate_model
    end

    start_model_file[association.name] = if intermediate_item&.one_polymorphic_names?(end_item) && association.has_many?
                                           ":#{end_item.real_item.name.pluralize}"
                                         else
                                           ":#{end_model}"
                                         end

    unless intermediate_item
      start_model_file['class_name'] = "\"#{end_item.real_item.name.camelize}\"" if end_item.clone_name_different?

      if polymorphic_end
        start_model_file['as'] = ":#{start_item.name}"
      elsif start_item.clone_name_different?
        start_model_file['foreign_key'] = "\"#{start_item.name.singularize}_id\""
      end
    end

    start_model_file['through'] = ":#{intermediate_model}" if through?(intermediate_item)

    if polymorphic_intermediate && intermediate_item.one_polymorphic_names?(end_item)
      start_model_file['source'] = ":#{end_item.name}"
      start_model_file['source_type'] = "\"#{end_item.real_item.name.camelize}\" "
    end

    open_model_file(start_model) do |file, tempfile|
      line_found = false
      file.each do |line|
        if (line.include?('end') || line.include?("through: :#{end_model}")) && !line_found
          line_found = true
          line_association = ''
          start_model_file.each do |key, value|
            line_association << if %w[has_many has_one].include?(key)
                                  "  #{key} #{value}"
                                else
                                  ", #{key}: #{value}"
                                end
          end

          line_association << "\n"
          tempfile << line_association
        end
        tempfile << line
      end
    end
  end

  def add_associations
    if parent_through?

      if parent_through_has_many?
        if parent.one_polymorphic_names?(self)
          update_model(self, parent, grand_association, nil, true)
        else
          update_model(self, parent, grand_association)
        end

        if parent.one_polymorphic_names?(grand) || parent.one_polymorphic_names?(self)
          update_model(self, grand, grand_association, parent, false, true)
        else
          update_model(self, grand, grand_association, parent)
        end

      elsif parent_through_has_one?
        update_model(parent, self, grand_association)
      end

      if parent.one_polymorphic_names?(grand) || parent.one_polymorphic_names?(self)
        update_model(grand, self, grand_association, parent, false, true)
      else
        update_model(grand, self, grand_association, parent)
      end

    end

    associations.each do |association|
      next unless association.has_any?

      association.second_items.each do |second_item|
        if second_item.one_polymorphic_names?(self)
          update_model(self, second_item, association, nil, true)
        else
          update_model(self, second_item, association)
        end
      end
    end
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
end
