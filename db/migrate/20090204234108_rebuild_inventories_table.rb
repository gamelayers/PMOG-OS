class RebuildInventoriesTable < ActiveRecord::Migration
  def self.up
    rename_table :inventories, :old_inventories
    
    User.reset_column_information
    Inventory.reset_column_information
    
    create_table 'inventories', :id => false, :force => true do |t|
      t.string   :id,              :limit => 36,    :null => false
      t.string   :owner_id,        :limit => 36,    :null => false
      t.string   :owner_type,                       :null => false
      t.integer  :mines,           :limit => 5,     :default => 0
      t.integer  :grenades,        :limit => 5,     :default => 0
      t.integer  :crates,          :limit => 5,     :default => 0
      t.integer  :lightposts,      :limit => 5,     :default => 0
      t.integer  :portals,         :limit => 5,     :default => 0
      t.integer  :armor,           :limit => 5,     :default => 0
      t.integer  :st_nicks,        :limit => 5,     :default => 0
      t.integer  :watchdogs,       :limit => 5,     :default => 0
      t.integer  :datapoints,      :limit => 11,    :default => 0
      t.integer  :pings,           :limit => 11,    :default => 0
      t.timestamps
    end

    # Create the indexes
    execute( "ALTER TABLE inventories ADD PRIMARY KEY(id)")
    add_index :inventories, [:owner_id, :owner_type]
    
    # Ditch old tools we won't need for a while
    rockets = Tool.find_by_name('rockets')
    rockets.destroy unless rockets.nil?
    walls = Tool.find_by_name('walls')
    walls.destroy unless walls.nil?
    
    # A hash of tool name => tool id
    tools = {}
    Tool.find(:all).collect{ |t| tools[t.name.to_sym] = t.id }
    
    counter = 0
    puts "Starting to migrate User inventories, #{User.count} to fulfill"
    
    # Copy over all the user inventories
    User.all do |user|
      user_inv = {}
      [:mines, :grenades, :crates, :lightposts, :portals, :armor, :st_nicks, :watchdogs].each do |tool|
        tool_id = tools[tool]
        user_inv[tool] = User.find_by_sql( "SELECT count(*) AS count_all 
                                            FROM   old_inventories 
                                            WHERE  slottable_id = '#{user.id}' 
                                            AND    slottable_type = 'User' 
                                            AND    tool_id = '#{tool_id}'" )[0].count_all rescue 0
      end

      puts "#{counter} user records complete ...." if (counter % 1000 == 0)
      Inventory.create( :owner_id => user.id, 
                        :owner_type => 'User',
                        :mines => user_inv[:mines],
                        :grenades => user_inv[:grenades],
                        :crates => user_inv[:crates],
                        :lightposts => user_inv[:lightposts],
                        :portals => user_inv[:portals],
                        :armor => user_inv[:armor],
                        :st_nicks => user_inv[:st_nicks],
                        :watchdogs => user_inv[:watchdogs],
                        :datapoints => 0,
                        :pings => 0
                      )
      counter += 1
    end

    puts "Users done, #{counter} records seen"
    puts "Starting to migrate Crate inventories, #{Crate.count} to fulfill"
    counter = 0
    
    # Copy over all the crate inventories
    Crate.all do |crate|
      crate_inv = {}
      [:mines, :grenades, :crates, :lightposts, :portals, :armor, :st_nicks, :watchdogs].each do |tool|
        tool_id = tools[tool]
        crate_inv[tool] = Crate.find_by_sql( "SELECT count(*) AS count_all 
                                              FROM   old_inventories 
                                              WHERE  slottable_id = '#{crate.id}' 
                                              AND    slottable_type = 'Crate' 
                                              AND    tool_id = '#{tool_id}'" )[0].count_all rescue 0
      end

      # Crates can store DP too, so let's grab that too
      crate_inv[:datapoints] = Crate.find_by_sql( "SELECT datapoints
                                                   FROM   old_inventories 
                                                   WHERE  slottable_id = '#{crate.id}' 
                                                   AND    slottable_type = 'Crate' 
                                                   AND    datapoints > 0" )[0].datapoints rescue 0
      
      puts "#{counter} crate records complete ...." if (counter % 1000 == 0)
      Inventory.create( :owner_id => crate.id, 
                        :owner_type => 'Crate',
                        :mines => crate_inv[:mines],
                        :grenades => crate_inv[:grenades],
                        :crates => crate_inv[:crates],
                        :lightposts => crate_inv[:lightposts],
                        :portals => crate_inv[:portals],
                        :armor => crate_inv[:armor],
                        :st_nicks => crate_inv[:st_nicks],
                        :watchdogs => crate_inv[:watchdogs],
                        :datapoints => crate_inv[:datapoints],
                        :pings => 0 # pings don't exist yet
                      )
      counter += 1
    end
    
    puts "Crates done, #{counter} records seen"
  end

  def self.down
    drop_table :inventories
    rename_table :old_inventories, :inventories
  end
end