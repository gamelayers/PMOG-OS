class ToolUsesIndexii < ActiveRecord::Migration
  def self.up
    remove_index :tool_uses, [:user_id, :tool_id, :created_at]
    add_index :tool_uses, [:user_id, :created_at, :tool_id]
  end

  def self.down
    remove_index :tool_uses, [:user_id, :created_at, :tool_id]
    add_index :tool_uses, [:user_id, :tool_id, :created_at]
  end
end
