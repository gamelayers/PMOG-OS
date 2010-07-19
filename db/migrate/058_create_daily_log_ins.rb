class CreateDailyLogIns < ActiveRecord::Migration
  def self.up
    create_table :daily_log_ins, :id => false do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.timestamps 
    end

    add_index :daily_log_ins, :id
    add_index :daily_log_ins, :user_id
    add_index :daily_log_ins, :created_at
  end

  def self.down
    drop_table :daily_log_ins
  end
end
