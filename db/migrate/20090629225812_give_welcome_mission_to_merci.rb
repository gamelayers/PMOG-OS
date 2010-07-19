class GiveWelcomeMissionToMerci < ActiveRecord::Migration
  def self.up
    # if IsStaging or IsProduction
    #   merci = User.find_by_login "merci"
    #   wttnn = Mission.find_by_url_name "welcome_to_the_nethernet"
    #
    #   wttnn.user_id = merci.id
    #   wttnn.save
    # end
  end

  def self.down
  end
end
