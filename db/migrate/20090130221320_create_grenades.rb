class CreateGrenades < ActiveRecord::Migration
  def self.up
    create_table :grenades, :id => false, :force => true do |t|
      t.string    :id,            :limit => 36
      t.string    :victim_id,     :limit => 36
      t.string    :perp_id,       :limit => 36
      t.integer   :charges,       :limit => 11, :default => 1
      t.timestamps
    end
    add_index :grenades, :victim_id
    add_index :grenades, :perp_id
    execute("ALTER TABLE grenades ADD PRIMARY KEY(id)")

    # insert/update the grenade entry in :tools
    grenade_data = Hash[:name => "grenades",
      :level => 10,
      :character => 'destroyer',
      :short_description => "Throw a grenade at another player to deal damage.",
      :long_description => "Grenades are used to damage another player in real time.  When you throw a grenade at someone, the next time that player moves to a new web page, it will explode, dealing damage.  Grenades can be stopped by St Nicks, and blocked or dodged by Bedouin.",
      :classpoints => 10,
      :damage => 10,
      :cost => 20,
      :icon_image => "icon_grenade_image_path",
      :medium_image => "medium_grenade_image_path"]
    
    Tool.reset_column_information
    @grenades = Tool.find_by_name("grenades")
    if(@grenades.nil?)
      Tool.create(grenade_data)
    else
      @grenades.update_attributes(grenade_data)
    end
  end

  def self.down
    drop_table :grenades
  end
end
