require 'json'
require 'table'
require 'entity'
require 'rest-client'

class EAD
  def warning(str, color = :red)
    if color == :red
      puts "\e[31m\n#{str}\n\e[0m"
    elsif :yellow
      puts "\e[33m\n#{str}\n\e[0m"
    end
  end

  def import_JSON(user_arguments)
    file = File.read(user_arguments[0] || './EAD.json')

    unless JSON.parse(file)['version'] == '0.4.7'
      puts "\n\n----------------"

      warning(
        'Versions of your EAD file and the gem are not compatible. ' \
        'To run your EAD file correctly, please run'
      )

      warning(
        "gem install ead -v #{JSON.parse(file)['version']}"
      )

      warning(
        'Or, upload your file to EAD(user interface) and download it again. It will be updated automatically.'
      )

      puts "----------------\n\n"

      raise StandardError, 'Incompatible version'
    end

    file
  end

  def create_objects(file)
    parsed_file = JSON.parse(file)

    parsed_tables = parsed_file['tables']
    parsed_nodes = parsed_file['nodes']
    parsed_edges = parsed_file['edges']

    @tables = parsed_tables.map { |id, parsed_table| Table.new(id, parsed_table) }

    Table.update_superclasses(parsed_tables)

    @nodes = parsed_nodes.map { |node| Entity.new(node) }

    Entity.dismiss_similar_ones

    @edges = parsed_edges.map { |edge| Association.new(edge) }

    Association.dismiss_similar_ones
    Association.set_all_middle_entities

    Table.all.each(&:set_polymorphic_names)
  end

  def check_implement_objects
    Table.all.each(&:create_model)

    Table.all.each(&:add_reference_migration)

    Association.all_references.each(&:update_model_from_entity)
  end

  def check_latest_version
    response = JSON.parse RestClient.get 'https://api.github.com/repos/ozovalihasan/ead/tags'

    unless response.first['name'] == 'v0.4.7'
      puts "\n\n----------------"
      warning(
        'A new version of this gem has been released. ' \
        'Please check it. https://github.com/ozovalihasan/ead-g/releases',
        :yellow
      )
      puts "----------------\n\n"
    end
  rescue StandardError
    puts "\n\n----------------"
    warning(
      'If you want to check the latest version of this gem, ' \
      'you need to have a stable internet connection.'
    )
    puts "\n----------------\n\n"
  end

  def start(user_arguments)
    check_latest_version
    file = import_JSON(user_arguments)
    create_objects(file)
    check_implement_objects
  end
end
