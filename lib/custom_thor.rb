require "thor"
require 'active_support/core_ext/string'


class CustomThor < Thor
  include Thor::Actions

  desc "hello", "says hello"

  option :name, required: true, type: :string
  option :line_content, required: true, type: :hash

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
