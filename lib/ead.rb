require 'json'
require 'fileutils'
require 'item'
require 'block'
require 'byebug'

class EAD
  def import_JSON(user_arguments)
    file = File.read(user_arguments[0] || './EAD.json')
    items = JSON.parse(file)
    ead_id = '8'
    Block.new(ead_id, items)
    Block.all.each do |block|
      next unless block.cloneable

      block.clone_blocks.map! do |id|
        Block.find(id.to_s)
      end
    end
  end

  def check_implement_items
    ead_id = '8'
    block = Block.find(ead_id)
    block.sub_blocks.each do |sub_block|
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
end
