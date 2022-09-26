require 'fileutils'
require_relative 'custom_thor'


class ProjectFile
  def self.open_close(name, type, &block)
    case type
    when 'migration'
      tempfile_name = './db/migrate/migration_update.rb'
      file_name = Dir.glob("./db/migrate/*_#{name.pluralize}.rb").first
    when 'model'
      tempfile_name = './app/models/model_update.rb'
      file_name = "./app/models/#{name}.rb"
    when 'reference_migration'
      tempfile_name = './db/migrate/migration_update.rb'
      file_name = Dir.glob("./db/migrate/*_#{name}.rb").first
    end
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

  def self.update_line(name, type, keywords, line_content)
    CustomThor.new.invoke(:update_line, [], { name: name, keywords: keywords, line_content: line_content, type: type})
  end

  def self.add_line(name, end_model, line_content)
    open_close(name, 'model') do |file, tempfile|
      line_found = false
      file.each do |line|
        if (line.include?('end') || line.include?("through: :#{end_model}")) && !line_found
          line_found = true
          line_association = ''
          line_content.each do |key, value|
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

  def self.add_belong_line(name, line_content)
    CustomThor.new.invoke(:add_belong_line, [], { name: name, line_content: line_content})
  end
  
  
end

