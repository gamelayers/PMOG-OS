class CreateBurdendayUserToReplacePmogUser < ActiveRecord::Migration
  def self.up
    unless User.find(:first, :conditions => {:login => 'burdenday'})
      user = User.new( :login => 'burdenday', :email => 'joe@gamelayers.com', :password => 'itsasekrit', :password_confirmation => 'itsasekrit' )
      user.save(false)
      UserLevel.create(:user_id => user.id)
      AbilityStatus.create(:user_id => user.id)
      Inventory.create(:owner_id => user.id, :owner_type => 'User')
    end
  end

  def self.down
    # No need to migrate down
  end
end

# Just create the user, nothing fancy
class UserObserver < ActiveRecord::Observer
  def after_create(user)
    true
  end
end