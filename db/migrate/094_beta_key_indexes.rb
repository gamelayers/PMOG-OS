class BetaKeyIndexes < ActiveRecord::Migration
  def self.up
    add_index :beta_keys, :user_id
  end

  def self.down
    remove_index :beta_keys, :user_id
  end
end
