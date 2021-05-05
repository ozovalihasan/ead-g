class Attribute
  attr_accessor :name, :type

  def initialize(name, type)
    @name = name
    @type = type
  end

  def add_to(command)
    command << " #{name}:#{type}"
  end
end
