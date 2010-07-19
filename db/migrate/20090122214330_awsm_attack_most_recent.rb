class AwsmAttackMostRecent < ActiveRecord::Migration
  def self.up
    execute( 'CREATE INDEX idx_most_recent ON awsmattacks(context, created_at)' )
  end

  def self.down
    execute( "ALTER TABLE awsmattacks DROP INDEX idx_most_recent" )
  end
end
