class CreateFbUsers < ActiveRecord::Migration
  def self.up
    create_table :fb_users, :force => true, :id => false do |t|
      t.column :pmog_id, :string, :limit => 36
      t.column :fb_id, :integer
      t.column :pref_prof_info, :integer, :limit => 2 , :default => 1
      t.column :pref_badges, :integer, :limit => 2, :default => 1
      t.column :pref_feed, :integer, :limit => 2, :default => 1
      t.column :pref_aquaint, :integer, :limit => 2, :default => 1
      t.timestamps
    end
    
    # MySQL's standard int isnt big enough for facebook's potential
    # size of a user's id
    execute("alter table fb_users modify fb_id bigint")
    
    add_index :fb_users, :pmog_id
    add_index :fb_users, :fb_id
  end


  def self.down
    drop_table :fb_users
  end
end