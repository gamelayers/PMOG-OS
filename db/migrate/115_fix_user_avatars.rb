# We've added a new image size, so this migration should force
# the re-creation of all the mission mini images
class FixUserAvatars < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      user.assets.each do |asset|
        asset.save
      end
    end
  end

  def self.down
    # No need to migrate down
  end
end
