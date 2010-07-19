class MissionBelongsToUser < ActiveRecord::Migration
  def self.up
    add_column :missions, :user_id, :string, :login => 36
  end

  def self.down
    remove_column :missions, :user_id
  end
end
