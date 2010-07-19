class ConnectingBranchesAndLocations < ActiveRecord::Migration
  def self.up
    add_column :branches, :location_id, :string, :limit => 36
    
    Branch.find(:all).each do |b|
      b.location_id = Location.find_or_create_by_url(b.url).id unless b.url.nil?
      b.save
    end

    remove_column :branches, :url
    
    add_index :branches, :location_id
  end

  def self.down
    add_column :branches, :url, :text
    
    Branch.find(:all).each do |b|
      b.url = Location.find(b.location_id).url unless b.url.nil?
      b.save
    end

    remove_column :branches, :location_id
  end
end
