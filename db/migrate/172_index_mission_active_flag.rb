class IndexMissionActiveFlag < ActiveRecord::Migration
  def self.up
    add_index :missions, :is_active
  end

  def self.down
    remove_index :missions, :is_active
  end
end
