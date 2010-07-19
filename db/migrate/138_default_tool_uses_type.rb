# We want to change the default usage type to be 'tool'
class DefaultToolUsesType < ActiveRecord::Migration
  def self.up
    execute "alter table tool_uses change usage_type usage_type varchar(255) default 'tool'"
  end

  def self.down
    execute "alter table tool_uses change usage_type usage_type varchar(255) default 'user'"
  end
end
