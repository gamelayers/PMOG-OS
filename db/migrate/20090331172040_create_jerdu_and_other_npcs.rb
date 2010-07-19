class CreateJerduAndOtherNpcs < ActiveRecord::Migration
  def self.up
    role = Role.create(:name => 'npc')

    unless User.find(:first, :conditions => {:login => 'jerdu_gains'})
      user = User.new( :login => 'jerdu_gains', :email => 'jerdu_gains@gamelayers.com', :url => 'thenethernet.com/guide/characters/jerdu_gains', :password => 'itsasekrit', :password_confirmation => 'itsasekrit', :motto => "Observe, orient, decide, act.")
      user.save(false)
      UserLevel.create(:user_id => user.id, :bedouin_cp => 50000, :primary_class => "bedouin")
      AbilityStatus.create(:user_id => user.id)
      Inventory.create(:owner_id => user.id, :owner_type => 'User')
      insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('#{user.id}', '#{role.id}', NOW(), NOW());" )
    end

  end

  def self.down
  end
end

class UserObserver < ActiveRecord::Observer
  def after_create(user)
    true
  end
end

