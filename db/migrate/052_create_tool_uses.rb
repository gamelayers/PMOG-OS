class CreateToolUses < ActiveRecord::Migration
  def self.up
    create_table :tool_uses, :id => false do |t|
      t.string :id, :limit => 36
      t.string :tool_id, :limit => 36
      t.string :user_id, :limit => 36
      t.timestamps 
    end
    
    add_index :tool_uses, :tool_id
    add_index :tool_uses, :user_id
    
    add_column :users, :primary_class, :string, :default => "shoat"
    add_column :users, :secondary_class, :string, :default => "shoat"
    add_column :users, :tertiary_class, :string, :default => "shoat"
    
    User.find(:all).each do |user|
      user.primary_class = "shoat"
      user.secondary_class = "shoat"
      user.tertiary_class = "shoat"
      user.date_of_birth = 33.years.ago
      user.save
    end
  end

  def self.down
    drop_table :tool_uses
    
    remove_column :users, :primary_class
    remove_column :users, :secondary_class
    remove_column :users, :tertiary_class  
  end
end
