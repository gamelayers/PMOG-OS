class CreateUserAcquaintanceStats < ActiveRecord::Migration
  def self.up
    create_table :user_acquaintance_stats, :id => false do |t|
      t.string :id, :null => false, :limit => 36
      t.integer :user_count, :acquaintance_count
      t.timestamps
    end
  end

  def self.down
    drop_table :user_acquaintance_stats
  end
end
