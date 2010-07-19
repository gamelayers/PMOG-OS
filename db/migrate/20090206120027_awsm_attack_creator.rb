class AwsmAttackCreator < ActiveRecord::Migration
  def self.up
    execute( "TRUNCATE TABLE awsmattacks" )
    add_column :awsmattacks, :creator_id, :string, :limit => 36, :null => false
  end

  def self.down
    remove_column :awsmattacks, :creator_id
  end
end
