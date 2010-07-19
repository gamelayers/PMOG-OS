class ChangeParanoidToActivated < ActiveRecord::Migration
  def self.up
      remove_column :posts, :deleted_at
      remove_column :topics, :deleted_at
      
      add_column :posts, :is_active, :boolean, :default => true
      add_column :topics, :is_active, :boolean, :default => true
  end

  def self.down
      remove_column :posts, :is_active
      remove_column :topics, :is_active

      add_column :topics, :deleted_at, :datetime
      add_column :posts, :deleted_at, :datetime
  end
end
