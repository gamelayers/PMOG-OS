class ToolUsesIndexes < ActiveRecord::Migration
  def self.up
    begin
      add_index :tool_uses, [:created_at, :user_id]
    rescue
      # nothing
    end

    begin
      add_index :ratings, [:created_at, :user_id]
    rescue
      # nothing
    end

    execute "alter table messages drop index index_messages_on_created_at, add index index_messages_on_created_at_and_user_id (created_at, user_id)"
  end

  def self.down
    add_index :messages, [:created_at]
    remove_index :messages, [:created_at, :user_id]
    remove_index :tool_uses, [:created_at, :user_id]
    remove_index :ratings, [:created_at, :user_id]
  end

end
