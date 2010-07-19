class BadgeInactivityFlag < ActiveRecord::Migration
  def self.up
    add_column :badges, :active, :boolean, :default => true
    Badge.reset_column_information

    # These badges are being retired or suspended
    ["Torch",
    "Snowglobe",
    "Fellow Traveller",
    "Lotus Drinkers",
    "Indie",
    "Achiever",
    "All About Mii",
    "Awrooo!",
    "Badges. We Has Them",
    "Better Than Halo 3",
    "Bounce Bounce",
    "Champion",
    "Crowd Control",
    "Dealers",
    "Dorian's Darlings",
    "Flying with Radar",
    "Fun Theory",
    "Great Beast",
    "KillahOm",
    "Little Birdie",
    "Mesmerized",
    "Queen Bee",
    "Science, It Works Bitches",
    "Soul Catcher",
    "Space is the Place",
    "Stop Motion",
    "Take Me To Your Readers",
    "The Red Tent",
    "Thumb Buster",
    "VC",
    "Web of Warcraft" ].each do |badge_name|
      badge = Badge.find_by_name(badge_name)
      badge.active = false
      badge.save
    end
  end

  def self.down
    remove_column :badges, :active
    Badge.reset_column_information
  end
end