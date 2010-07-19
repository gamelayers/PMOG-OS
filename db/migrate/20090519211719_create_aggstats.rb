class CreateAggstats < ActiveRecord::Migration
  def self.up
    create_table :aggstats do |t|
      t.timestamps

      t.date :stat_on
      t.integer :period, :default => 0

      t.integer :agg_type, :default => 0 # 0 = daily, 1 = weekly, 2 = monthly, 3 = yearly

      t.integer :new_users, :default => 0
      t.integer :users_logged_in, :default => 0

      t.integer :users_connected_in, :default => 0

      t.integer :downloaded_toolbars, :default => 0
      t.integer :installed_toolbars, :default => 0
      t.integer :users_logged_in_toolbar, :default => 0 # pinging the site from toolbar

      t.integer :users_active, :default => 0
      t.integer :users_reactive, :default => 0

      t.integer :users_using_tools, :default => 0
      t.integer :tools_used, :default => 0
      t.integer :urls_deployed_on, :default => 0
      t.integer :tlds_deployed_on, :default => 0

      t.integer :missions_created, :default => 0
      t.integer :users_creating_missions, :default => 0

      t.integer :missions_taken, :default => 0
      t.integer :users_taking_missions, :default => 0

      t.integer :missions_dismissed, :default => 0
      t.integer :users_dismissing_missions, :default => 0

      t.integer :missions_queued, :default => 0
      t.integer :users_queueing_missions, :default => 0

      t.integer :missions_completed, :default => 0
      t.integer :users_completing_missions, :default => 0

      t.integer :events, :default => 0

      t.integer :pmails_sent, :default => 0
      t.integer :users_sending_pmails, :default => 0

      t.integer :forum_posts, :default => 0
      t.integer :users_posting_to_forums, :default => 0

      t.integer :users_rating_users, :default => 0
      t.integer :users_rating_missions, :default => 0

      t.integer :users_level_0, :default => 0
      t.integer :users_level_1, :default => 0
      t.integer :users_level_2, :default => 0
      t.integer :users_level_3, :default => 0
      t.integer :users_level_4, :default => 0
      t.integer :users_level_5, :default => 0
      t.integer :users_level_6, :default => 0
      t.integer :users_level_7, :default => 0
      t.integer :users_level_8, :default => 0
      t.integer :users_level_9, :default => 0
      t.integer :users_level_10, :default => 0

      t.integer :nethertweets, :default => 0
    end

    add_index :aggstats, [:stat_on, :period]
  end

  def self.down
    remove_index :aggstats, [:stat_on, :period]
    drop_table :aggstats
  end
end
