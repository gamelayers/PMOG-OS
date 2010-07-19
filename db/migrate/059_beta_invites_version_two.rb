class BetaInvitesVersionTwo < ActiveRecord::Migration
  def self.up
    add_column :users, :beta_key_id, :string, :limit => 10
    add_column :beta_keys, :user_id, :string, :limit => 36
    add_column :beta_users, :beta_key_id, :int
  end

  def self.down
    remove_column :users, :beta_key_id
    remove_column :beta_keys, :user_id
    remove_column :beta_users, :beta_key_id
  end
end
