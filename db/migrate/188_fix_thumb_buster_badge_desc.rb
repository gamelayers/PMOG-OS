class FixThumbBusterBadgeDesc < ActiveRecord::Migration
  def self.up
    tbBadge = Badge.find_by_name( "Thumb Buster" )
    unless tbBadge.nil?
      tbBadge.description = "Visit any of kotaku.com, joystiq.com, eurogamer.net or gamespot.com once a week for a month."
      tbBadge.save
    end
  end

  def self.down
  end
end
