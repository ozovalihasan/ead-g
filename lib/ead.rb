require 'json'
require 'table'
require 'entity'
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

      raise StandardError, msg = 'Incompatible version'
    end

    file
  end

  def create_objects(file)
    @nodes = JSON.parse(file)['nodes']
    @edges = JSON.parse(file)['edges']
    @tables = JSON.parse(file)['tables']

    @tables = @tables.map do |(id)|
      Table.new(id, @tables)
    end

    @nodes.map! do |node|
      Entity.new(node)
    end

    @edges.map! do |edge|
      Association.new(edge)
    end
  end

  def check_implement_objects(file)
    create_objects(file)

    Entity.all.each do |entity|
      entity.clone_parent.entities << entity
    end

    Table.all.each(&:create_model)

    Table.all.each(&:add_reference_migration)

    Association.set_middle_entities

    Association.all.each do |association|
      association.first_entity.update_model(association.second_entity, association)
    end
  end

  def check_latest_version
    response = JSON.parse RestClient.get 'https://api.github.com/repos/ozovalihasan/ead/tags'

    unless response.first['name'] == 'v0.3.1'
      puts "\n\n----------------"
      puts "\n\e[33m#{
        'A new version of this gem has been released.'\
          ' Please check it. https://github.com/ozovalihasan/ead-g/releases'
      }\e[0m"

      puts "\n----------------\n\n"
    end
  rescue StandardError
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
    check_implement_objects(file)
  end
end
