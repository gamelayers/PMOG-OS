class AddDefaultValueToUserRating < ActiveRecord::Migration
  def self.up
    remove_column :users, :average_rating
    remove_column :users, :total_ratings
    
    add_column :users, :average_rating, :integer, :default => 0
    add_column :users, :total_ratings, :integer, :default => 0
  end

  def self.down
    # no reason to support .down here, migration 191 will drop these same columns and all we've changed is the default value
  end
end
