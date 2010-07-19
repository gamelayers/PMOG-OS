class CreateUserLevels < ActiveRecord::Migration
  def self.up
    create_table :user_levels, :id => false, :force => true do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.string :primary_class, :default => 'shoat'
      t.integer :bedouin_cp, :default => 0
      t.integer :benefactor_cp, :default => 0
      t.integer :destroyer_cp, :default => 0
      t.integer :pathmaker_cp, :default => 0
      t.integer :seer_cp, :default => 0
      t.integer :vigilante_cp, :default => 0
      t.timestamps
    end
    execute( "ALTER TABLE user_levels ADD PRIMARY KEY(id)")

    # build and seed the new xp-per-use field
    add_column :tools, :classpoints, :integer, :limit => 11
    add_column :upgrades, :classpoints, :integer, :limit => 11
    add_column :abilities, :classpoints, :integer, :limit => 11

    @tools = Tool.find(:all)
    @tools.each do |tool|
      tool.classpoints = 5
      tool.save
    end

    @upgrades = Upgrade.find(:all)
    @upgrades.each do |upgrade|
      upgrade.classpoints = 5
      upgrade.save
    end

    @abilities = Ability.find(:all)
    @abilities.each do |ability|
      ability.classpoints = 5
      ability.save
    end

    # seeding the classpoints reqs w/ my favorite pattern
    add_column :levels, :classpoints, :integer, :limit => 11
    @levels = Level.find(:all)
    fib1=1
    fib2=0
    @levels.each do |level|
      level.classpoints = fib1+fib2
      fib2 = fib1
      fib1 = level.classpoints
      level.save
    end
  end

  def self.down
    drop_table :user_levels

    remove_column :tools, :classpoints
    remove_column :upgrades, :classpoints
    remove_column :abilities, :classpoints

    remove_column :levels, :classpoints
  end
end
