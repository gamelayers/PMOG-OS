class TotalUserDatapoints < ActiveRecord::Migration
  def self.up
    add_column :users, :total_datapoints, :integer, :default => 0, :null => false
    
    User.find(:all).each do |u|
      u.total_datapoints = u.datapoints
      u.date_of_birth = 33.years.ago
      u.save
    end
  end

  def self.down
    remove_column :users, :total_datapoints
  end
end
