class ToolUsesIndexForOrderVsChaos < ActiveRecord::Migration
  def self.up
    add_index :tool_uses, [:user_id, :tool_id, :created_at]
  end

  def self.down
    remove_index :tool_uses, [:user_id, :tool_id, :created_at]
  end
end
