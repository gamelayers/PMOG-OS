# We've added a new image size, so this migration should force
# the re-creation of all the avatars for the user profile page
class CreateProfileAssets < ActiveRecord::Migration
  def self.up
    # Moved to a background job, see jobs/create_profile_assets.rb
    #User.all(100) do |user|
    #  unless user.assets.nil? or user.assets.empty? or user.assets[0].nil?
    #    user.assets[0].update_attributes(nil)
    #  end
    #end
  end

  def self.down
    # No need to migrate down
  end
end
