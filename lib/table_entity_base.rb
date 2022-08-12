class TableEntityBase


  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.find(id)
    all.find { |base| base.id == id }
  end
end
