require 'json'
require 'item'
require 'item_clone'
require 'block'

class EAD
  def import_JSON(user_arguments)
    file = File.read(user_arguments[0] || './EAD.json')
    items = JSON.parse(file)['items']
    ead_id = '9'
    Block.new(ead_id, items)
    Block.all.each do |block|
      next unless block.cloneable

      block.clone_blocks.map! do |id|
        Block.find(id.to_s)
      end
    end
  end

  def create_items(block)
    block.sub_blocks.each do |sub_block|
      if sub_block.entity
        Item.new(sub_block)
      elsif sub_block.entity_clone
        ItemClone.new(sub_block)
      elsif sub_block.entity_container || sub_block.entity_association
        create_items(sub_block)
      end
    end
  end

  def check_implement_items
    ead_id = '9'
    block = Block.find(ead_id)
    create_items(block)

    ItemClone.all.each do |item_clone|
      parent = Item.find(item_clone.clone_parent)
      item_clone.clone_parent = Item.find(item_clone.clone_parent)
      parent.clones << item_clone
    end

    Item.all.each do |item|
      item.create_migration
    end

    ItemClone.all.each do |item_clone|
      item_clone.add_associations
    end
  end

  def start(user_arguments)
    import_JSON(user_arguments)
    check_implement_items
  end
end
