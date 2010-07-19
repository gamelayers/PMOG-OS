class CreateDailyDomains < ActiveRecord::Migration
  def self.up
    create_table :daily_domains, :id => false do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.string :location_id, :limit => 36
      t.timestamps 
    end
    
    add_index :daily_domains, :id
    add_index :daily_domains, :user_id
    add_index :daily_domains, :location_id
  end

  def self.down
    drop_table :daily_domains
  end
end
