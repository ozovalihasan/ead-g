require 'json'
require 'item'
require 'item_clone'
require 'rest-client'

class EAD
  def import_JSON(user_arguments)
    file = File.read(user_arguments[0] || './EAD.json')

    unless ['0.4.0'].include? JSON.parse(file)['version']
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

    return file
    
    # items = JSON.parse(file)['items']
    # ead_id = '9'
    # ead_block = Block.new(ead_id, items)
    # Block.all.each do |block|
    #   next unless block.cloneable

    #   block.clone_blocks.map! do |id|
    #     Block.find(id.to_s)
    #   end
    # end
  end

  def create_items(file)
    @nodes = JSON.parse(file)['nodes']
    @edges = JSON.parse(file)['edges']
    @tables = JSON.parse(file)['tables']

    
    @tables = @tables.map do |(id)|
      Item.new(id, @tables)
    end

    @nodes.map! do |node|
      ItemClone.new(node)
    end

    @edges.map! do |edge|
      Association.new(edge)
    end

  end

  def check_implement_items(file)
    create_items(file)

    ItemClone.all.each do |item_clone|
      item_clone.clone_parent.clones << item_clone
    end

    Item.all.each do |item|
      item.create_model
    end

    # ItemClone.all.each do |item_clone|
    #   item_clone.add_associations
    # end

    Association.all.each do |association|
      association.first_item.update_model(association.second_item, association)
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
    file = import_JSON(user_arguments)
    check_implement_items(file)
  end
end
