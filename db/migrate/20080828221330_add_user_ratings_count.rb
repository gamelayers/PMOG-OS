class AddUserRatingsCount < ActiveRecord::Migration
  def self.up
    add_column :users, :ratings_count, :integer, :default => 0
    
    User.reset_column_information
    User.find(:all).each do |u|
      User.update_counters u.id, :ratings_count => u.ratings.length
    end
  end

  def self.down
    remove_column :users, :ratings_count
  end
end
