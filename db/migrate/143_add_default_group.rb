class AddDefaultGroup < ActiveRecord::Migration
  def self.up
    Group.new(:name => "Default").save
  end

  def self.down
    
  end
end
