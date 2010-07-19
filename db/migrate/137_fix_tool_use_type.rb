class FixToolUseType < ActiveRecord::Migration
  # Rails treats columns called 'type' as reserved for STI
  # So let's rename them to usage_type instead.
  def self.up
    execute "alter table tool_uses change type usage_type varchar(255) default 'user'"
  end

  def self.down
    execute "alter table tool_uses change usage_type type varchar(255) default 'user'"
  end
end
