class IndexPortalAverageRating < ActiveRecord::Migration
  def self.up
    add_index :portals, [:average_rating, :created_at]
  end

  def self.down
    remove_index :portals, [:average_rating, :created_at]
  end
end
