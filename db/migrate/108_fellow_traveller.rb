class FellowTraveller < ActiveRecord::Migration
  def self.up
    Badge.create( :name => "Fellow Traveller", :description => "For players who complete more than 8 missions." )
  end

  def self.down
    # see migration 186 for notes on why we cant .down gracefully

    #badge = Badge.find_by_name( "Fellow Traveller" )
    #badge.destroy
  end
end
