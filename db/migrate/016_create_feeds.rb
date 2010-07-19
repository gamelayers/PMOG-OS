class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :url, :string
    end

    add_index :feeds, :id
    add_index :feeds, :url
  end

  def self.down
    drop_table :feeds
  end
end
