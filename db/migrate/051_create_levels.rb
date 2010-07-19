class CreateLevels < ActiveRecord::Migration
  def self.up
    create_table :levels, :id => false do |t|
      t.string :id, :limit => 36
      t.integer :level, :null => false, :default => 0
      t.integer :datapoints, :null => false, :default => 0
      t.integer :missions_created, :null => false, :default => 0
      t.integer :missions_taken, :null => false, :default => 0
    end

    Level.create( :level => 1, :datapoints => 0, :missions_created => 0, :missions_taken => 0 )
    Level.create( :level => 2, :datapoints => 2000, :missions_created => 1, :missions_taken => 2 )
    Level.create( :level => 3, :datapoints => 6000, :missions_created => 2, :missions_taken => 4 )
    Level.create( :level => 4, :datapoints => 12000, :missions_created => 3, :missions_taken => 6 )
    Level.create( :level => 5, :datapoints => 20000, :missions_created => 4, :missions_taken => 8 )
    Level.create( :level => 6, :datapoints => 30000, :missions_created => 5, :missions_taken => 10 )
    Level.create( :level => 7, :datapoints => 42000, :missions_created => 6, :missions_taken => 12 )
    Level.create( :level => 8, :datapoints => 56000, :missions_created => 7, :missions_taken => 14 )
    Level.create( :level => 9, :datapoints => 72000, :missions_created => 8, :missions_taken => 16 )
    Level.create( :level => 10, :datapoints => 90000, :missions_created => 9, :missions_taken => 18 )
    Level.create( :level => 11, :datapoints => 110000, :missions_created => 10, :missions_taken => 20 )
    Level.create( :level => 12, :datapoints => 132000, :missions_created => 11, :missions_taken => 22 )
    Level.create( :level => 13, :datapoints => 156000, :missions_created => 12, :missions_taken => 24 )
    Level.create( :level => 14, :datapoints => 182000, :missions_created => 13, :missions_taken => 26 )
    Level.create( :level => 15, :datapoints => 210000, :missions_created => 14, :missions_taken => 28 )
    Level.create( :level => 16, :datapoints => 240000, :missions_created => 15, :missions_taken => 30 )
    Level.create( :level => 17, :datapoints => 272000, :missions_created => 16, :missions_taken => 32 )
    Level.create( :level => 18, :datapoints => 306000, :missions_created => 17, :missions_taken => 34 )
    Level.create( :level => 19, :datapoints => 342000, :missions_created => 18, :missions_taken => 36 )
    Level.create( :level => 20, :datapoints => 380000, :missions_created => 19, :missions_taken => 38 )
  end

  def self.down
    drop_table :levels
  end
end