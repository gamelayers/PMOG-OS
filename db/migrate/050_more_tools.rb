class MoreTools < ActiveRecord::Migration
  def self.up    
    self.update_tool_cost :lightposts, 10
    self.update_tool_cost :portals, 10
    self.update_tool_cost :mines, 10
    self.update_tool_cost :crates, 5
    
    Tool.create( :name => 'rockets', :description => 'Can be fired at walls built on websites. Each rocket removes 5 bricks.', :cost => 10, :character => 'grenadier')
    Tool.create( :name => 'walls', :description => 'Walls can be built around sites to prevent mines from being laid on them. The player must then fire a rocket to dislodge the wall. Each wall has 20 blocks. Each rocket takes out 5 of the blocks. Greater than 5 blocks in a wall, and no mines can be laid on that spot.', :cost => 10, :character => 'riveter')
    Tool.create( :name => 'st_nicks', :description => 'They attach to a user and abort one effort by that user to deploy either rockets or mines.', :cost => 10, :character => 'vigilante')
    Tool.create( :name => 'armor', :description => 'Can be purchased by a player and prevents the player and their datapoints from damage. Each set of armor lasts for 10 unique URLs if worn. Players can remove the armor and save the remaining charges on their armor.', :cost => 15, :character => 'bedouin')
  end

  def self.down
    self.destroy_tool :rockets
    self.destroy_tool :walls
    self.destroy_tool :st_nicks
    self.destroy_tool :armor
  end

  def self.update_tool_cost(tool_name, cost)
    Tool.find_by_name(tool_name.to_s).update_attributes(:cost => cost)
  end

  def self.destroy_tool(tool_name)
    Tool.find_by_name(tool_name.to_s).destroy rescue nil
  end
end
