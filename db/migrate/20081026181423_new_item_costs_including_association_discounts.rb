class NewItemCostsIncludingAssociationDiscounts < ActiveRecord::Migration

  @@original_cost = {
    :crates => 10,
    :lightposts => 40,
    :armor => 25,
    :st_nicks => 40,
    :mines => 40,
    :portals => 75,
    :rockets => 99999,
    :walls => 99999
  }

  @@public_cost = {
    :crates => 40,
    :lightposts => 160,
    :armor => 100,
    :st_nicks => 160,
    :mines => 160,
    :portals => 300,
    :rockets => 99999,
    :walls => 99999
  }
  
  @@association_cost = {
    :crates => 10,
    :lightposts => 40,
    :armor => 25,
    :st_nicks => 40,
    :mines => 40,
    :portals => 75,
    :rockets => 99999,
    :walls => 99999
  }

  def self.up
    Tool.find(:all).each do |tool|
      tool.cost = @@public_cost[tool.name.to_sym]
      tool.association_cost = @@association_cost[tool.name.to_sym]
      tool.save
    end
  end

  def self.down
    Tool.find(:all).each do |tool|
      tool.cost = @@original_cost[tool.name.to_sym]
      tool.association_cost = 0
      tool.save
    end
  end
end
