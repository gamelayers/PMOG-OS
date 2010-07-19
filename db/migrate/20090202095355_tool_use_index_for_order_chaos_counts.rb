class ToolUseIndexForOrderChaosCounts < ActiveRecord::Migration
  def self.up
    add_index :tool_uses, [:tool_id, :created_at]
  end

  def self.down
    remove_index :tool_uses, [:tool_id, :created_at]
  end
end
