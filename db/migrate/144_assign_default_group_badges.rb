class AssignDefaultGroupBadges < ActiveRecord::Migration
  def self.up
    group = Group.find_by_name('Default')
    badges = Badge.find(:all)
    badges.each do |badge|
      badge.group_id = group.id
      badge.save
    end
  end

  def self.down
  end
end
