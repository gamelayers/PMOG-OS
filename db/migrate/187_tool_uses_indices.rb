class ToolUsesIndices < ActiveRecord::Migration
  # Courtesy of EngineYard, see ticket YPJ-572965
  # Seems my indices from migration 173 weren't that hot :(
  # Plus, here's an index for missions that'll come in useful too...
  def self.up
    execute "ALTER TABLE tool_uses DROP INDEX total, DROP INDEX user_total, ADD INDEX idx_tool_uses_on_usage_type_tool_id_user_id (usage_type, tool_id, user_id)"
    execute "CREATE INDEX index_tags_on_tag_id ON tags(id)"
    execute "CREATE INDEX index_missions_on_is_active_and_association ON missions(is_active, association)"
  end

  def self.down
    execute "DROP INDEX idx_tool_uses_on_usage_type_tool_id_user_id ON tool_uses"
    execute "CREATE INDEX `total` ON `tool_uses` (`usage_type`, `tool_id`)"
    execute "CREATE INDEX `user_total` ON `tool_uses` (`usage_type`, `user_id`, `tool_id`)"
    execute "DROP INDEX index_tags_on_tag_id ON tags"
    execute "DROP INDEX index_missions_on_is_active_and_association ON missions"
  end
end
