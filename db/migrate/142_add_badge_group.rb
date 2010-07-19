class AddBadgeGroup < ActiveRecord::Migration
  def self.up
    add_column :badges, :group_id, :string, :limit => 36
    
    add_index :badges, :group_id, :name => "fk_badge_group"
  end

  def self.down
    remove_column :badges, :group_id
  end
end
