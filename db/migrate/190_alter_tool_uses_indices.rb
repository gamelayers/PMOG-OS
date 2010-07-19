class AlterToolUsesIndices < ActiveRecord::Migration
  # Note that EngineYard suggested we implement the index called
  # idx_tool_uses_on_usage_type_tool_id_user_id, but I'm not  sure it's used all that much.
  def self.up

    # Everything must go!
    execute "TRUNCATE TABLE tool_uses"

    remove_index :tool_uses, :tool_id
    remove_index :tool_uses, :user_id
    execute "DROP INDEX idx_tool_uses_on_usage_type_tool_id_user_id ON tool_uses"
    execute "CREATE INDEX idx_tool_uses_on_user_id_tool_id_usage_type ON tool_uses (user_id, tool_id, usage_type)"
    execute "CREATE INDEX idx_tool_uses_on_tool_id_usage_type ON tool_uses (tool_id, usage_type)"
    
    execute "OPTIMIZE TABLE tool_uses"
  end

  def self.down
    execute "CREATE INDEX idx_tool_uses_on_usage_type_tool_id_user_id ON tool_uses (usage_type, tool_id, user_id)"
    execute "DROP INDEX idx_tool_uses_on_user_id_tool_id_usage_type ON tool_uses"
    execute "DROP INDEX idx_tool_uses_on_tool_id_usage_type ON tool_uses"
    add_index :tool_uses, :tool_id
    add_index :tool_uses, :user_id
  end
end
