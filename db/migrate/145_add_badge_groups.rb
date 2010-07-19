class AddBadgeGroups < ActiveRecord::Migration
  def self.up
    Group.new(:name => "URL/Surfing").save
    Group.new(:name => "Tool Use").save
    Group.new(:name => "Mission Creation").save
    Group.new(:name => "PMOG").save
  end

  def self.down
    Group.find_by_name("URL/Surfing").destroy
    Group.find_by_name("Tool Use").destroy
    Group.find_by_name("Mission Creation").destroy
    Group.find_by_name("PMOG").destroy
  end
end
