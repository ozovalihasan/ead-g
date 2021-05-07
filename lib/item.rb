require 'attribute'
require 'association'
require 'fileutils'
require 'active_support/core_ext/string'


class Item
  attr_accessor :name, :parent, :grand_parent_item, :associations, :attributes

  def initialize(block, parent = { item: nil, association: nil }, grand_parent_item = nil)
    @name = block.content
    @parent = parent
    @grand_parent_item = grand_parent_item
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

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def create_migration
    command = 'bundle exec rails generate model '
    parent_association = parent[:association] ? parent[:association].name : nil
    model_name = name.capitalize.singularize
    command << model_name
    attributes.each { |attribute| attribute.add_to(command) }

    if %w[has_many has_one].include? parent_association
      command << " #{parent[:item].name.downcase.singularize}:references"
    end

    system(command)
  end

  def add_associations_to_model
    def update_model(start_model, end_model, association, through = false, intermediate_model = '')
      start_model.downcase!
      tempfile = File.open('./app/models/model_update.rb', 'w')
      f = File.new("./app/models/#{start_model}.rb")
      f.each do |line|
        tempfile << line
        next unless line.include? 'class'

        tempfile << if %w[belongs_to has_one].include? association
                      "  #{association} :#{end_model.downcase.singularize}\n"
                    elsif through
                      "  #{association} :#{end_model.downcase.pluralize}, "\
                      "through: :#{intermediate_model.downcase.pluralize}\n"
                    else
                      "  #{association} :#{end_model.downcase.pluralize}\n"
                    end
      end
      f.close
      tempfile.close

      FileUtils.mv('./app/models/model_update.rb', "./app/models/#{start_model}.rb")
    end

    parent_association = parent[:association] ? parent[:association].name : nil
    if parent_association == ':through'
      update_model(name, parent[:item].name, 'has_many')
      update_model(grand_parent_item.name, name, 'has_many', true, parent[:item].name)
      update_model(name, grand_parent_item.name, 'has_many', true, parent[:item].name)
      update_model(parent[:item].name, name, 'belongs_to')
    end

    associations.each do |association|
      next unless %w[has_many has_one].include? association.name

      association.second_items.each do |second_item|
        update_model(name, second_item.name, association.name)
      end
    end
  end
end
