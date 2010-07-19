class MissionRatings < ActiveRecord::Migration
  def self.up
    add_column :missions, :average_rating, :integer, :default => 0
  end

  def self.down
    remove_column :missions, :average_rating
  end
end
