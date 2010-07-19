class PmogUser < ActiveRecord::Migration
  def self.up
    user = User.new( :login => 'pmog', :email => 'self@pmog.com', :password => 'itsasekrit', :password_confirmation => 'itsasekrit' )
    user.save(false)
  end

  def self.down
    # No need to migrate down
  end
end

# Disable this as it breaks the creation of our very first user, PMOG
class UserObserver < ActiveRecord::Observer
  def after_create(user)
    true
  end
end
