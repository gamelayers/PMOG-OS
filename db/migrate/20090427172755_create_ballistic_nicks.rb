class CreateBallisticNicks < ActiveRecord::Migration
  def self.up
    create_table :ballistic_nicks do |t|
      t.string  :victim_id, :limit => 36
      t.string  :perp_id, :limit => 36
      t.timestamps
    end

    GameSetting.create(:key => 'Max Ballistic Nicks per Player', :value => 3)
  end

  def self.down
    drop_table :ballistic_nicks

    max_ballistic_nicks = GameSetting.find_by_key('Max Ballistic Nicks per Player')
    max_ballistic_nicks.destroy
  end
end
