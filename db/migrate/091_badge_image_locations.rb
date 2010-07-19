class BadgeImageLocations < ActiveRecord::Migration
  def self.up
    Badge.find(:all).each do |badge|
      #badge.image = badge.create_permalink(badge.name.downcase)
      badge.image = "default.png"
      badge.save
    end
  end

  def self.down
    # n/a
  end
end
