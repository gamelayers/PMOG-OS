class SetDefaultNsfwPreference < ActiveRecord::Migration
  def self.up
    @users = User.find(:all)
    for user in @users
        user.preferences.set Preference.preferences[:allow_nsfw][:text], "false"
    end
  end

  def self.down
  end
end
