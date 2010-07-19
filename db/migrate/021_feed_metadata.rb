class FeedMetadata < ActiveRecord::Migration
  def self.up
    add_column :feeds, :etag, :string
    add_column :feeds, :last_modified, :datetime
    add_column :feeds, :error, :string

    add_column :messages, :syndication_id, :string
    add_column :messages, :media_type, :string
    add_index :messages, [:feed_id, :syndication_id]
  end

  def self.down
    remove_column :feeds, :etag
    remove_column :feeds, :last_modified
    remove_column :feeds, :error
    remove_index :messages, [:feed_id, :syndication_id]
  end
end
