class AddFieldsToLevels < ActiveRecord::Migration
  def self.up
    add_column :levels, :armors_donned, :integer, :default => 0
    add_column :levels, :crates_deployed, :integer, :default => 0
    add_column :levels, :lightposts_deployed, :integer, :default => 0
    add_column :levels, :mines_deployed, :integer, :default => 0
    add_column :levels, :portals_deployed, :integer, :default => 0
    add_column :levels, :portals_taken, :integer, :default => 0
    add_column :levels, :rockets_fired, :integer, :default => 0
    add_column :levels, :walls_deployed, :integer, :default => 0
    add_column :levels, :st_nicks_attached, :integer, :default => 0
  end

  def self.down
    remove_column :levels, :armors_donned
    remove_column :levels, :crates_deployed
    remove_column :levels, :lightposts_deployed
    remove_column :levels, :mines_deployed
    remove_column :levels, :portals_deployed
    remove_column :levels, :portals_taken
    remove_column :levels, :rockets_fired
    remove_column :levels, :walls_deployed
    remove_column :levels, :st_nicks_attached
  end
end
