class DatabaseIndexes < ActiveRecord::Migration
  def self.up
    execute "create index index_topics_on_is_active_url_name_id on topics (is_active, url_name, id)"
  end

  def self.down
    execute "drop index index_topics_on_is_active_url_name_id on topics"
  end
end
