class LocationCreatedAt < ActiveRecord::Migration
  def self.up
    add_column :locations, :created_at, :datetime
    
    Location.find(:all).each do |l|
      l.created_at = Time.now
      l.save
    end
  end

  def self.down
    remove_column :locations, :created_at
  end
end
