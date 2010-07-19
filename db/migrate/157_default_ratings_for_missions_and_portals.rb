class DefaultRatingsForMissionsAndPortals < ActiveRecord::Migration
  def self.up
    pmog_user = User.find_by_email 'self@pmog.com'

    Mission.find(:all).each do |mission|
      if mission.ratings.empty?
        mission.ratings.create( :user_id => pmog_user.id, :score => 3 )
        mission.calculate_average_rating
      end
    end
    
    Portal.find(:all).each do |portal|
      if portal.ratings.empty?
        portal.ratings.create( :user_id => pmog_user.id, :score => 3 )
        portal.calculate_average_rating
      end
    end
  end

  def self.down
    # No real need to migrate down from this
  end
end
