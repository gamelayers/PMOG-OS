class OptOutOfMissionInvites < ActiveRecord::Migration
  def self.up
    add_column :mission_shares, :optout, :boolean, :default => false
  end

  def self.down
    remove_column :mission_shares, :optout
  end
end
