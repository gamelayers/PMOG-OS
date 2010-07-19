class AddUserAvgRating < ActiveRecord::Migration
  def self.up
    add_column :users, :average_rating, :integer
    add_column :users, :total_ratings, :integer
  end

  def self.down
    remove_column :users, :average_rating
    remove_column :users, :total_ratings
  end
end
