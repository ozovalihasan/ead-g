require "thor"
require 'active_support/core_ext/string'


class CustomThor < Thor
  include Thor::Actions

  desc "hello", "says hello"

  option :name, required: true, type: :string
  option :line_content, required: true, type: :hash
  option :keywords, type: :string
  option :type, type: :string

  def update_line
    file_name = nil
    if options[:type] == "reference_migration"
      file_name = "./db/migrate/*_#{options[:name]}.rb"
    end

    regexp_to_select_all_line = /^.*#{options[:keywords]}.*$/

    gsub_file(file_name, regexp_to_select_all_line) do |line|
      
      options[:line_content].each do |key, value|
        if line.include? key
          line.gsub!(/#{key}: [^(\s,)]*/, "#{key}: #{value}")
        else
          line << ", #{key}: #{value}"
        end
      end  
      line
    end

  end
  
  desc "hello", "says hello"

  def add_belong_line
    line_association = ''
    
    options[:line_content].each do |key, value|
      line_association << if %w[belongs_to].include?(key)
                            "  #{key} #{value}"
                          else
                            ", #{key}: #{value}"
                          end
    end

    line_association << "\n"

    inject_into_class("app/models/#{options[:name]}.rb", options[:name].classify, line_association )
  end
end
