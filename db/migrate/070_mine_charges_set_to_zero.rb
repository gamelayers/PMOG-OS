class MineChargesSetToZero < ActiveRecord::Migration
  def self.up
    # Update the default Mine charges to 1
    mine = Tool.find_by_name( 'mines' )
    mine.charges = 1
    mine.save
  end

  def self.down
    # Reset the default Mine charges to 5
    mine = Tool.find_by_name( 'mines' )
    mine.charges = 5
    mine.save
  end
end