# We have a url validator that is causing some users to be unsaveable
# since they have personal urls on the user model that are now considered invalid.
# This migration attempts to fix that problem by correcting any invalide user urls
# and forcing a save. Symptoms of this problem include untaggable users, and fixed associations.
class ValidateUserUrls < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      unless user.valid?
        if user.errors.on(:url)
          user.url = Url.normalise(user.url)
          user.save(false)
        end
      end
    end
  end

  def self.down
    # No real need to migrate down from this
  end
end

# Note that user.url has been overridden in migration 005
# So we need to reset that and return the correct field in here:
class User
  def url
    self.attributes["url"]
  end
end