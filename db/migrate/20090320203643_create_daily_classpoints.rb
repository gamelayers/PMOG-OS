class CreateDailyClasspoints < ActiveRecord::Migration
  def self.up
    create_table :daily_classpoints do |t|
      t.string      :user_id,         :limit => 36
      t.string      :pmog_class_id,   :limit => 36
      t.integer     :points,          :limit => 11
      t.timestamps
    end
  end

  def self.down
    drop_table :daily_classpoints
  end
end
