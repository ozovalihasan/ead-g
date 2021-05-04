require 'rails'
require 'json'
require 'fileutils'
require 'pry'
require 'byebug'

class Association
  attr_accessor :first_item
  attr_accessor :second_items
  attr_accessor :name

  def initialize(first_item, item)
    @first_item = first_item
    @second_items = []
    @name = item.content
    if item.sub_blocks
      item.sub_blocks.map do |sub_block|
        @second_items << Item.new(sub_block, {item: first_item, association: self}, first_item.parent[:item])
      end
    end
  end

end

class Attribute
  attr_accessor :name
  attr_accessor :type

  def initialize(name, type)
    @name = name
    @type = type
  end

  def add_to(command)
    command << " #{name}:#{type}"
  end
  
end

class Item
  attr_accessor :name
  attr_accessor :parent
  attr_accessor :grand_parent_item
  attr_accessor :associations
  attr_accessor :attributes

  def initialize(block, parent = { item: nil, association: nil}, grand_parent_item = nil )
    @name = block.content
    @parent = parent
    @grand_parent_item = grand_parent_item
    @attributes = []
    @associations = []

    block.sub_blocks.map do |sub_block|
      if sub_block.attribute
        @attributes << Attribute.new(sub_block.content,sub_block.type)
      elsif  sub_block.attribute_container
        sub_block.sub_blocks.map do |attribute|
          @attributes << Attribute.new(attribute.content,attribute.type)
        end
      elsif sub_block.association
        @associations << Association.new(self,sub_block)
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
    attributes.each {|attribute| attribute.add_to(command)} 

    if ['has_many','has_one'].include? parent_association
      command << " #{parent[:item].name.downcase.singularize}:references"
    end

    system(command)
  end

  def add_associations_to_model
    parent_association = parent[:association] ? parent[:association].name : nil
    if parent_association == 'belongs_to'
      update_model(name,parent[:item].name,'has_many')
      update_model(grand_parent.name,name,'has_many', true, parent[:item].name)
      update_model(name,grand_parent.name,'has_many', true, parent[:item].name)
      update_model(parent[:item].name,name,'belongs_to')
    end

    associations.each do |association|
      if ['has_many', 'has_one'].include? association.name
        association.second_items.each do |second_item|
          update_model(name,second_item.name,association.name)
        end
      end
    end
  end
end

class Block
  attr_accessor :id,:content,:category,:attribute_container,:attribute,:type,:association,:sub_blocks
  
  def initialize(id,items)
    item = items[id]
    @id = id
    @content = item["content"]
    @category = item["category"]
    @attribute_container = item["attributeContainer"]
    @attribute = item["attribute"]
    @type = item["type"]
    @association = item["association"]
    @sub_blocks = []
    item["subItemIds"].map do |id|
      id = id.to_s 
      @sub_blocks << Block.new(id,items)
    end
  end

  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.find(id)
    all.each {|block| return block if block.id == id}
  end

end


def update_model(start_model,end_model,association, through=false, indermediate_model="")
  start_model.downcase!
  tempfile=File.open("./app/models/model_update.rb", 'w')
  f=File.new("./app/models/#{start_model}.rb")
  f.each do |line|
    tempfile << line
    if line.include? 'class'
      if ['belongs_to', 'has_one'].include? association 
        tempfile << "  #{association} :#{end_model.downcase.singularize}\n"  
      elsif through
        tempfile << "  #{association} :#{end_model.downcase.pluralize}, through: :#{indermediate_model.downcase.pluralize}\n"  
      else
        tempfile << "  #{association} :#{end_model.downcase.pluralize}\n"  
      end
    end
  end
  f.close
  tempfile.close

  FileUtils.mv("./app/models/model_update.rb", "./app/models/#{start_model}.rb")
end

def import_JSON(user_arguments)
  file = File.read(user_arguments[0] || './EAD.json')
  items = JSON.parse(file)
  ead_id = "8"
  Block.new(ead_id, items)
end

def check_implement_items
  ead_id = "8"
  block = Block.find(ead_id)
  block.sub_blocks.map do |sub_block|
    Item.new(sub_block)
  end

  Item.all.reverse.each do |item|
    item.create_migration
    item.add_associations_to_model
  end
end

def start(user_arguments)
  import_JSON(user_arguments)
  check_implement_items
end
