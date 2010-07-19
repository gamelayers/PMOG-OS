class CreateThomasHogginsIfHeDoesNotExist < ActiveRecord::Migration
  def self.up
    unless User.find(:first, :conditions => {:login => 'thomas_hoggins'})
      user = User.new( :login => 'thomas_hoggins', :email => 'thomas_hoggins@gamelayers.com', :password => 'itsasekrit', :password_confirmation => 'itsasekrit' )
      user.save(false)
      UserLevel.create(:user_id => user.id)
      AbilityStatus.create(:user_id => user.id)
      Inventory.create(:owner_id => user.id, :owner_type => 'User')
    end
  end

  def self.down
  end
end

# Just create the user, nothing fancy
class UserObserver < ActiveRecord::Observer
  def after_create(user)
    true
  end
end