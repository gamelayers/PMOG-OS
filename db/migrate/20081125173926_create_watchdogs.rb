class CreateWatchdogs < ActiveRecord::Migration
  def self.up
    create_table :watchdogs, :id => false, :force => true do |t|
      t.string   :id,             :limit => 36
      t.string   :location_id,    :limit => 36
      t.string   :user_id,        :limit => 36
      t.timestamps
    end

    add_column :tools, :level, :integer, :default => 1, :limit => 11

    Tool.reset_column_information

    Tool.create(:name => 'watchdogs', :level => 5, :medium_image =>"/fuck/off/rails/", :icon_image => "/this/should/allow/nulls/imo/", :short_description => "Chases a busy destroyer away from a URL.  Has not gotten a rabies shot this year.", :cost => 40, :character => 'vigilante')
  end

  def self.down
    drop_table :watchdogs

    remove_column :tools, :level

    Tool.find_by_name('watchdogs').destroy
  end
end
