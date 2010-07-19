class TrackMissionInviteConversion < ActiveRecord::Migration
  def self.up
    add_column :mission_shares, :converted, :boolean, :default => false
  end

  def self.down
    remove_column :mission_shares, :converted
  end
end
