class CreateAwsmattacks < ActiveRecord::Migration
  def self.up
    create_table :awsmattacks, :id => false do |t|
      t.string :id, :limit => 36, :null => false
      t.string :user_id, :limit => 36, :null => false
      t.string :location_id, :limit => 36, :null => false
      t.string :context, :null => false
      t.integer :week, :limit => 2, :null => false
      t.integer :month, :limit => 2, :null => false
      t.integer :year, :limit => 2, :null => false
      t.timestamps
    end

    execute( "ALTER TABLE awsmattacks ADD PRIMARY KEY(id)")
  
    # Doing these by hand since Rails creates index names too long for MySQL
    execute( "CREATE INDEX `idx_awsm_on_user_id_and_location_id_and_context_and_created_at` ON `awsmattacks` (`user_id`, `location_id`, `context`, `created_at`)" )
    execute( "CREATE INDEX `idx_awsm_on_location_id_and_context_and_created_at` ON `awsmattacks` (`location_id`, `context`, `created_at`)" )
    execute( "CREATE INDEX `idx_awsm_on_year_and_month_and_week` ON `awsmattacks` (`year`, `month`, `week`)" )
  end

  def self.down
    drop_table :awsmattacks
  end
end
