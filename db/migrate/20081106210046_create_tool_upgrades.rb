class CreateToolUpgrades < ActiveRecord::Migration
  def self.up

    create_table :upgrades, :id => false do |t|
      #GENERIC FIELDS
      t.string :id, :limit => 36
      t.string :name
      t.string :url_name
      t.string :tool_id, :limit => 36
      t.string :association_id, :limit => 36
      t.integer :level, :limit => 11
      t.string :short_description
      t.string :icon_image
      t.string :small_image
      t.string :medium_image
      t.string :large_image
      t.text :long_description
      t.text :history
      #UPGRADE SPECIFIC FIELDS
      #   the following columns are just some guesses as to the kind of variables merci will want to tweak.
      # in reality the models will have complete control over how costs end up calculated.
      #   complex costs like 1 mine and 1 crate for an exploding crate can still be representeted.
      # a developer will have to be told in a ticket in order to implement changes in logic like that (unavoidable)
      # and the |tool|_upgrades tables may need to be expanded to support the new feature (unfortunate, but also unavoidable).
      #   the misc field is there to represent some other arbitrary cost or effect
      # we don't want a developer to have to tweak any constants written directly into the model, so if you're looking to do a quick hack please that stuff here instead.
      # the misc field stored as an int, so it could also be used with enumeration for a state based upgrade.
      # most importantly, more fields can be added easily if it makes more sense to use them instead;
      # this table is designed to be expanded to support arbitrarily complex upgrade designs.
      t.integer :dp_cost, :limit => 11
      t.integer :ping_cost, :limit => 11
      t.integer :armor_cost, :limit => 11, :default => 0
      t.integer :crate_cost, :limit => 11, :default => 0
      t.integer :lightpost_cost, :limit => 11, :default => 0
      t.integer :mine_cost, :limit => 11, :default => 0
      t.integer :portal_cost, :limit => 11, :default => 0
      t.integer :st_nick_cost, :limit => 11, :default => 0
      t.integer :damage, :limit => 11, :default => 0
      t.integer :misc, :limit => 11
      t.timestamps
    end
    execute("ALTER TABLE upgrades ADD PRIMARY KEY(id)")
    add_index :upgrades, :url_name
    add_index :upgrades, :tool_id

    # seeding the first 3 upgrades
    # seeding will have to be done manually in the future as well
    # :url_name is used by coders so you should set it here and then NOT CHANGE IT, it'll be referenced in the models
    # regular :name is used by merci (can be changed whenever who cares)

    Upgrade.create( :name => 'Tollbooth',
      :url_name => 'give_dp',
      :short_description => 'Sends you a message and gives you 2 DP whenever a user takes your portal',
      :tool_id => Tool.find_by_name('portals').id,
      :association_id => PmogClass.find_by_name('Seers').id,
      :level => 5,
      :ping_cost => 20)


    Upgrade.create( :name => 'Puzzle Crate',
      :url_name => 'puzzle_crate',
      :short_description => 'Locks a crate',
      :tool_id => Tool.find_by_name('crates').id,
      :association_id => PmogClass.find_by_name('Benefactors').id,
      :level => 10,
      :ping_cost => 15)


    Upgrade.create( :name => 'Exploding Crate',
      :url_name => 'exploding_crate',
      :short_description => 'Just like a crate, except its actually a mine',
      :tool_id => Tool.find_by_name('crates').id,
      :association_id => PmogClass.find_by_name('Destroyers').id,
      :level => 5,
      :mine_cost => 1,
      :damage => 10,
      :ping_cost => 15)

    Ping.create(:name => 'rival_explodes_crate',
      :points => 10)


    # ttl goes in the tool table
    add_column :crates, :charges, :integer, :limit => 11, :default => 1


    # for tracking association changes to the player

    create_table :upgrade_uses, :id => false do |t|
      t.string :id, :limit => 36
      t.string :upgrade_id, :limit => 36
      t.string :user_id, :limit => 36
      t.integer :points, :limit => 11
      t.timestamps
    end
    execute("ALTER TABLE upgrade_uses ADD PRIMARY KEY(id)")
    add_index :upgrade_uses, :user_id


    # for tracking the actual game events

    create_table :crate_upgrades, :id => false do |t|
      t.string :id, :limit => 36
      t.string :crate_id, :limit => 36
      t.string :puzzle_question
      t.string :puzzle_answer
      t.boolean :exploding
      t.timestamps
    end
    execute("ALTER TABLE crate_upgrades ADD PRIMARY KEY(id)")
    add_index :crate_upgrades, :crate_id

    create_table :mine_upgrades, :id => false do |t|
      t.string :id, :limit => 36
      t.string :mine_id, :limit => 36
      t.integer :damage
      t.timestamps
    end
    execute("ALTER TABLE mine_upgrades ADD PRIMARY KEY(id)")
    add_index :mine_upgrades, :mine_id

    create_table :portal_upgrades, :id => false do |t|
      t.string :id, :limit => 36
      t.string :portal_id, :limit => 36
      t.boolean :give_dp
      t.timestamps
    end
    execute("ALTER TABLE portal_upgrades ADD PRIMARY KEY(id)")
    add_index :portal_upgrades, :portal_id

    create_table :st_nick_upgrades, :id => false do |t|
      t.string :id, :limit => 36
      t.string :st_nick_id, :limit => 36
      t.boolean :ballistic
      t.timestamps
    end
    execute("ALTER TABLE st_nick_upgrades ADD PRIMARY KEY(id)")
    add_index :st_nick_upgrades, :st_nick_id

    create_table :lightpost_upgrades, :id=> false do |t|
      t.string :id, :limit => 36
      t.string :lightpost_id, :limit => 36
      t.boolean :gravity_well
      t.timestamps
    end
    execute("ALTER TABLE lightpost_upgrades ADD PRIMARY KEY(id)")
    add_index :lightpost_upgrades, :lightpost_id

  end

  def self.down
    drop_table :upgrades

    drop_table :upgrade_uses

    remove_column :crates, :charges

    drop_table :crate_upgrades
    drop_table :mine_upgrades
    drop_table :lightpost_upgrades
    drop_table :portal_upgrades
    drop_table :st_nick_upgrades
  end
end
