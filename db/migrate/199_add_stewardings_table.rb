class AddStewardingsTable < ActiveRecord::Migration
  def self.up
    create_table :stewardings, :id => false, :force => true do |t|
      t.string :user_id, :limit => 36
      t.string :action
      t.string :topic_id, :limit => 36, :null => true
      t.string :forum_id, :limit => 36, :null => true
      t.timestamps
    end
  end
  
  def self.down
    drop_table :stewardings
  end
end
    
