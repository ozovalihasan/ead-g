require 'json'
require 'item'
require 'item_clone'
require 'block'
require 'rest-client'

class EAD
  def import_JSON(user_arguments)
    file = File.read(user_arguments[0] || './EAD.json')

    unless ['0.3.0','0.3.1'].include? JSON.parse(file)['version']
      puts "\n\n----------------"
      puts "\e[31m#{
        'Versions of your EAD file and the gem are not compatible.'\
        ' So, you may have some unexpected results.'\
        'To run your EAD file correctly, please run'
      }\e[0m"

      puts "\e[31m#{
        "\ngem install ead -v #{JSON.parse(file)['version']}"
      }\e[0m"
      puts "----------------\n\n"

      raise StandardError.new(msg="Incompatible version")
    end

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

  def check_latest_version
    # response = RestClient::Request.new(:method => :get, :url => 'https://api.github.com/repos/ozovalihasan/ead/tags')
    # response = JSON.parse response
    response = JSON.parse RestClient.get 'https://api.github.com/repos/ozovalihasan/ead/tags'
    
    unless response.first['name'] == "v0.3.1"
      puts "\n\n----------------"
      puts "\n\e[33m#{
        'A new version of this gem has been released.'\
        ' Please check it. https://github.com/ozovalihasan/ead-g/releases'
      }\e[0m"

      puts "\n----------------\n\n"
    end
  rescue
    puts "\n\n----------------"
    puts "\n\e[31m#{
      'If you want to check the latest version of this gem,'\
      ' you need to have a stable internet connection.'
    }\e[0m"

    puts "\n----------------\n\n"
  end

  def start(user_arguments)
    check_latest_version
    import_JSON(user_arguments)
    check_implement_items
  end
end
