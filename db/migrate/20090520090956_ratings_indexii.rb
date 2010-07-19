class RatingsIndexii < ActiveRecord::Migration
  def self.up
    add_index :ratings, [:user_id, :created_at, :rateable_type]
  end

  def self.down
    remove_index :ratings, [:user_id, :created_at, :rateable_type]
  end
end
