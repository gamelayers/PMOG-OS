class AddDailyInviteBuffsToAbilityStatuses < ActiveRecord::Migration
  def self.up
    add_column :ability_statuses, :daily_invite_buffs, :integer
  end

  def self.down
    remove_column :ability_statuses, :daily_invite_buffs
  end
end
