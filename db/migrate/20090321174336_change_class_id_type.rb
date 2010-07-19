class ChangeClassIdType < ActiveRecord::Migration
  def self.up
    change_column :daily_classpoints, :pmog_class_id, :integer
  end

  def self.down
  end
end
