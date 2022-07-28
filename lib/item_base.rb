class ItemBase


  def self.all
    ObjectSpace.each_object(self).to_a
  end

  def self.find(id)
    all.find { |item| item.id == id }
  end
end
