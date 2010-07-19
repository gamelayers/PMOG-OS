class ToolDamages < ActiveRecord::Migration
  def self.up
    mine_tool = Tool.find( :first, :conditions => { :name => "mines" } )
    mine_tool.damage = 10
    mine_tool.save
  end

  def self.down
    mine_tool = Tool.find( :first, :conditions => { :name => "mines" } )
    mine_tool.damage = 0
    mine_tool.save
  end
end
