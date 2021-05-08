require 'attribute'
require 'association'
require 'fileutils'
require 'active_support/core_ext/string'

class Item
  attr_accessor :name, :parent, :associations, :attributes

  def initialize(block, parent = { item: nil, association: nil })
    @name = block.content.downcase.singularize
    @parent = parent
    @attributes = []
    @associations = []

    block.sub_blocks.map do |sub_block|
      if sub_block.attribute
        @attributes << Attribute.new(sub_block.content, sub_block.type)
      elsif sub_block.attribute_container
        sub_block.sub_blocks.map do |attribute|
          @attributes << Attribute.new(attribute.content, attribute.type)
        end
      elsif sub_block.association
        @associations << Association.new(self, sub_block)
      end
    end
  end

  def grand_parent
    parent[:item].parent
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def create_migration
    return if File.exist?("./app/models/#{name.downcase.singularize}.rb")
    command = 'bundle exec rails generate model '
    parent_association = parent[:association] ? parent[:association].name : nil
    model_name = name.capitalize.singularize
    command << model_name
    attributes.each { |attribute| attribute.add_to(command) }

    if %w[has_many has_one].include? parent_association
      command << " #{parent[:item].name.downcase.singularize}:references"
    elsif parent_association == ':through'
      if parent[:item].parent[:association].name == 'has_one'
        command << " #{parent[:item].name.downcase.singularize}:references"
      end
    end

    if parent_association == 'has_many'
      through_association = associations.select { |association| association.name == ':through' }[0]
      if through_association
        through_association.second_items[0].create_migration
        command << " #{through_association.second_items[0].name.downcase.singularize}:references"
      end
    end

    system(command)
  end

  def add_associations_to_model
    def update_model(start_model, end_model, association, through = false, intermediate_model = '')
      start_model.downcase!
      tempfile = File.open('./app/models/model_update.rb', 'w')
      f = File.new("./app/models/#{start_model.downcase.singularize}.rb")
      f.each do |line|
        if line.include? 'end'

          tempfile << if through
                        if association == 'has_many'
                          "  #{association} :#{end_model.downcase.pluralize}, "\
                          "through: :#{intermediate_model.downcase.pluralize}\n"
                        elsif association == 'has_one'
                          "  #{association} :#{end_model.downcase.singularize}, "\
                          "through: :#{intermediate_model.downcase.singularize}\n"
                        end
                      elsif association == 'has_one'
                        "  #{association} :#{end_model.downcase.singularize}\n"
                      elsif association == 'has_many'
                        "  #{association} :#{end_model.downcase.pluralize}\n"
                      end
        end
        tempfile << line
      end
      f.close
      tempfile.close

      FileUtils.mv('./app/models/model_update.rb', "./app/models/#{start_model.downcase.singularize}.rb")
    end

    parent_association = parent[:association] ? parent[:association].name : nil
    if parent_association == ':through'
      if parent[:item].parent[:association].name == 'has_many'
        update_model(name, parent[:item].name, 'has_many')
        update_model(grand_parent[:item].name, name, 'has_many', true, parent[:item].name)
        update_model(name, grand_parent[:item].name, 'has_many', true, parent[:item].name)
      elsif parent[:item].parent[:association].name == 'has_one'
        update_model(parent[:item].name, name, 'has_one')
        update_model(grand_parent[:item].name, name, 'has_one', true, parent[:item].name)
      end
    end

    associations.each do |association|
      next unless %w[has_many has_one].include? association.name

      association.second_items.each do |second_item|
        update_model(name, second_item.name, association.name)
      end
    end
  end
end
