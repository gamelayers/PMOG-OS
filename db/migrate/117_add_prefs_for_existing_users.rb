class AddPrefsForExistingUsers < ActiveRecord::Migration
  def self.up
    #Adds the preferences to every user if they don't already have them defined (should be everyone first migration)
    @users = User.find(:all)
    for user in @users
    Preference.preferences.each {|option|
      user.preferences.toggle option[1][:text], option[1][:default]
    }
    end
  end
  
  def self.down
  end
end
