class SetDefaultSkinPreference < ActiveRecord::Migration
  def self.up
    @users = User.find(:all)
    for user in @users
        user.preferences.set Preference.preferences[:skin][:text], "classic"
    end
  end

  def self.down
  end
end
