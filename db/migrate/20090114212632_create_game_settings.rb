class CreateGameSettings < ActiveRecord::Migration
  def self.up
    create_table :game_settings do |t|
      t.string :key
      t.string :value
      t.timestamps
    end
    add_index :game_settings, :key

    GameSetting.create( :key => "DP for wearing Armor", :value => 2 )
    GameSetting.create( :key => "DP for not wearing Armor", :value => 3 )
  end

  def self.down
    drop_table :game_settings
  end
end
