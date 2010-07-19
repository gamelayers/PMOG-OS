class AddIndexToDailyClasspoints < ActiveRecord::Migration
  def self.up
    add_index :daily_classpoints, [:user_id, :pmog_class_id]
  end

  def self.down
  end
end
