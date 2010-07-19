class BadgeLocations < ActiveRecord::Migration
  def self.up
    create_table :badges_locations, :id => false do |t| 
      t.string :badge_id, :limit => 36
      t.string :location_id,:limit => 36
    end 
    add_index :badges_locations, :badge_id
    add_index :badges_locations, :location_id
    
    badges = {
      'Bounce Bounce' => [ 'http://boingboing.net' ],
      'VC' => [ 'http://techcrunch.com' ],
      'Science, It Works Bitches' => [ 'http://xkcd.com' ],
      'Achiever' => [ 'http://xbox360achievements.org', 'http://xbox.com' ],
      'All About Mii' => [ 'http://nintendo.com' ],
      'Indie' => [ 'http://google.com', 'http://google.co.uk'  ],
      'Dorian\'s Darlings' => [ 'http://facebook.com' ],
      'Space is the Place' => [ 'http://myspace.com' ],
      'Mesmerized' => [ 'http://youtube.com' ],
      'Soul Catcher' => [ 'http://flickr.com' ],
      'Take Me to Your Readers' => [ 'http://io9.com' ],
      'Little Birdie' => [ 'http://twitter.com' ],
      'The Red Tent' => [ 'http://jezebel.com' ],
      'Flying With Radar' => [ 'http://dopplr.com' ],
      'Awrooo!' => [ 'http://oreilly.com' ],
      'Thumb Buster' => [ 'http://kotaku.com', 'http://joystiq.com', 'http://eurogamer.net', 'http://gamespot.com' ],
      'Web of Warcraft' => [ 'http://worldofwarcraft.com', 'http://thottbot.com', 'http://wowinsider.com' ],
      'KillahOm' => [ 'http://gigaom.com' ],
      'Crowd Control' => [ 'http://massively.com' ],
      'Lotus Drinkers' => [ 'http://valleywag.com' ],
      'Dealers' => [ 'http://digg.com' ],
      'Better Than Halo 3' => [ 'http://eurogamer.net' ],
      'Queen Bee' => [ 'http://perezhilton.com' ],
      'Great Beast' => [ 'http://metafilter.com' ],
      'Stop Motion' => [ 'http://reddit.com' ],
      'Badges. We has them' => [ 'http://icanhascheezburger.com' ],
      'Fun Theory' => [ 'http://raphkoster.com' ],
      'Champion' => [ 'http://change-congress.org' ]
    }

    # Now create the badge locations
    badges.each do |badge_name|
      badge = Badge.find_by_name(badge_name[0])
      badges[badge_name[0]].each do |url|
        location = Location.find_or_create_by_url(url)
        badge.locations << location
      end
      badge.save
    end
  end

  def self.down
    drop_table :badges_locations
  end
end
