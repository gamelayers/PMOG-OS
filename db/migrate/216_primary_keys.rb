# Using UUIDs are primary keys is great in theory, but it fucks us up in all sorts of other ways.
# Not least the fact that mysql cries when it attempts to join two tables on char(36) keys, but also
# because Rails migrations just leave you to your own devices, meaning a bunch of our tables 
# ended up without primary keys. This migration fixes that in a couple of places - duncan 26th July 2008
class PrimaryKeys < ActiveRecord::Migration
  def self.up
    # There are no indices on the 'id' column for these tables, so adding a pk is straightforward
    execute( "ALTER TABLE dismissals ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE ratings ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE tool_uses ADD PRIMARY KEY(id)")

    # These tables have indices on the 'id' column already, so the pk will duplicate that
    execute( "ALTER TABLE messages ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE messages DROP INDEX index_messages_on_id")
    
    execute( "ALTER TABLE badges ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE badges DROP INDEX index_badges_on_id")
    
    execute( "ALTER TABLE users ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE users DROP INDEX index_users_on_id")
    
    execute( "ALTER TABLE hourly_activities ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE hourly_activities DROP INDEX index_hourly_activities_on_id")
    
    execute( "ALTER TABLE inventories ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE inventories DROP INDEX index_inventories_on_id")
    
    execute( "ALTER TABLE events ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE events DROP INDEX index_events_on_id")

    # Something extra for Queued Missions
    execute( "ALTER TABLE queued_missions ADD PRIMARY KEY(id)")
    add_index :queued_missions, :user_id
  end

  def self.down
    execute( "ALTER TABLE events DROP PRIMARY KEY")
    add_index :events, :id

    execute( "ALTER TABLE dismissals DROP PRIMARY KEY")
    execute( "ALTER TABLE ratings DROP PRIMARY KEY")
    execute( "ALTER TABLE tool_uses DROP PRIMARY KEY")
    
    execute( "ALTER TABLE messages DROP PRIMARY KEY")
    add_index :messages, :id
    
    execute( "ALTER TABLE badges DROP PRIMARY KEY")
    add_index :badges, :id
    
    execute( "ALTER TABLE users DROP PRIMARY KEY")
    add_index :users, :id
    
    execute( "ALTER TABLE hourly_activities DROP PRIMARY KEY")
    add_index :hourly_activities, :id
    
    execute( "ALTER TABLE inventories DROP PRIMARY KEY")
    add_index :inventories, :id
    
    execute( "ALTER TABLE queued_missions DROP PRIMARY KEY")
    remove_index :queued_missions, :user_id
  end
end
