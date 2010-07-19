class ToolUsePoints < ActiveRecord::Migration
  def self.up
    add_column :tool_uses, :points, :float, :null => false
    
    # Tool Uses now have a points column, and every tool use
    # is worth 1 point, with the exception of mines
    Tool.find(:all).each do |tool|
      if tool.name == "mines"
        execute( "UPDATE tool_uses SET points = 0.5 WHERE tool_id = '#{tool.id}'")
      else
        execute( "UPDATE tool_uses SET points = 1 WHERE tool_id = '#{tool.id}'")
      end
    end
  end

  def self.down
    remove_column :tool_uses, :points
  end
end
