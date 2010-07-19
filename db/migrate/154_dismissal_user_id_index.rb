class DismissalUserIdIndex < ActiveRecord::Migration
  def self.up
    add_index :dismissals, :user_id
  end

  def self.down
    remove_index :dismissals, :user_id
  end
end
