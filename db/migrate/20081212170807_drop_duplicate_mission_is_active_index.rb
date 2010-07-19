class DropDuplicateMissionIsActiveIndex < ActiveRecord::Migration
  def self.up
    remove_index :missions, :is_active
  end

  def self.down
    add_index :missions, :is_active
  end
end
