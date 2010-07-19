class ToolUseIndexes < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX `total` ON `tool_uses` (`usage_type`, `tool_id`)"
    execute "CREATE INDEX `user_total` ON `tool_uses` (`usage_type`, `user_id`, `tool_id`)"
  end

  def self.down
    execute "DROP INDEX `total` ON tool_uses"
    execute "DROP INDEX `user_total` ON tool_uses"
  end
end
