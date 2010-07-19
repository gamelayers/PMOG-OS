class FixTrailOfSplintersText < ActiveRecord::Migration
  def self.up
    badge = Badge.find_by_name("Trail of Splinters")
    if badge.nil?
      badge = Badge.create( :name => "Trail Of Splinters", :description => "For players who use more than 250 Crates")
    else
      badge.name = "Trail Of Splinters"
    end
    badge.save
  end

  def self.down
    #see migration 186 for notes on why we can't .down gracefully

    #badge = Badge.find_by_name( "Trail of Splinters" )
    #badge.destroy
  end
end
