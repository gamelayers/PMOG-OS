class FixValleyWagBadge < ActiveRecord::Migration
  def self.up
    badge = Badge.find_by_name 'Lotus Drinkers'
    badge.locations = []
    badge.locations << Location.find_or_create_by_url( 'http://valleywag.gawker.com' )
    badge.save
  end

  def self.down
    badge = Badge.find_by_name 'Lotus Drinkers'
    badge.locations = []
    badge.locations << Location.find_or_create_by_url( 'http://valleywag.com' )
    badge.save
  end
end
