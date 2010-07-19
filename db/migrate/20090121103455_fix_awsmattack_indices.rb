class FixAwsmattackIndices < ActiveRecord::Migration
  def self.up
    # Premature optimisation, we don't need these yet. They can be put back later - duncan 21/01/09
    execute( "ALTER TABLE awsmattacks DROP INDEX idx_most_recent" )
    execute( "ALTER TABLE awsmattacks DROP INDEX idx_awsm_on_user_id_and_location_id_and_context_and_created_at" )
    execute( "ALTER TABLE awsmattacks DROP INDEX idx_awsm_on_location_id_and_context_and_created_at" )
    execute( "ALTER TABLE awsmattacks DROP INDEX idx_awsm_on_year_and_month_and_week" )

    # These we need for overall awsm/attack by user, and awsm by user and attack by user
    execute( "CREATE INDEX idx_awsm_in_user_id_created_at ON awsmattacks (user_id, created_at)" ) 
    execute( "CREATE INDEX idx_awsm_in_user_id_context_created_at ON awsmattacks (user_id, context, created_at)" ) 
  end

  def self.down
    execute( 'CREATE INDEX idx_most_recent ON awsmattacks(context, created_at)' )
    execute( "CREATE INDEX `idx_awsm_on_user_id_and_location_id_and_context_and_created_at` ON `awsmattacks` (`user_id`, `location_id`, `context`, `created_at`)" )
    execute( "CREATE INDEX `idx_awsm_on_location_id_and_context_and_created_at` ON `awsmattacks` (`location_id`, `context`, `created_at`)" )
    execute( "CREATE INDEX `idx_awsm_on_year_and_month_and_week` ON `awsmattacks` (`year`, `month`, `week`)" )

    execute( "ALTER TABLE awsmattacks DROP INDEX idx_awsm_in_user_id_created_at" )
    execute( "ALTER TABLE awsmattacks DROP INDEX idx_awsm_in_user_id_context_created_at" )
  end
end
