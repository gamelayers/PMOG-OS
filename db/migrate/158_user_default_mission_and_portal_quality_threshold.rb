# Set the default rating for missions and users to 3
class UserDefaultMissionAndPortalQualityThreshold < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      portal_rating = user.preferences.get( Preference.preferences[:minimum_portal_rating][:text] )
      if portal_rating.nil? or portal_rating.value.to_i == 0
        user.preferences.set( Preference.preferences[:minimum_portal_rating][:text], 3 )
      end

      mission_rating = user.preferences.get( Preference.preferences[:minimum_mission_rating][:text] )
      if mission_rating.nil? or mission_rating.value.to_i == 0
        user.preferences.set( Preference.preferences[:minimum_mission_rating][:text], 3 )
      end
    end
  end

  def self.down
    # No real need to migrate down from this
  end
end
