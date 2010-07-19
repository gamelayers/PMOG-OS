class MessedStewardingsUpAlready < ActiveRecord::Migration
  def self.up
    add_column :stewardings, :stewardable_id, :string, :limit => 36
    add_column :stewardings, :stewardable_type, :string
    remove_column :stewardings, :topic_id
    remove_column :stewardings, :forum_id
  end
  
  def self.down
    remove_column :stewardings, :stewardable_id
    remove_column :stewardings, :stewardable_type
    add_column :stewardings, :topic_id, :string, :limit => 36, :null => true
    add_column :stewardings, :forum_id, :string, :limit => 36, :null => true
  end
end
