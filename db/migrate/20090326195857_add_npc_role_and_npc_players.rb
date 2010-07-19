class AddNpcRoleAndNpcPlayers < ActiveRecord::Migration
  def self.up
    role = Role.create(:name => 'npc')

    unless User.find(:first, :conditions => {:login => 'victoria_ash'})
      user = User.new( :login => 'victoria_ash', :email => 'victoria_ash@gamelayers.com',
                                                 :password => 'itsasekrit',
                                                 :password_confirmation => 'itsasekrit')
      user.save(false)
      UserLevel.create(:user_id => user.id, :primary_class => "vigilante")
      AbilityStatus.create(:user_id => user.id)
      Inventory.create(:owner_id => user.id, :owner_type => 'User')
      insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('#{user.id}', '#{role.id}', NOW(), NOW());" )
    end

    unless User.find(:first, :conditions => {:login => 'bloody_tuesday'})
      user = User.new( :login => 'bloody_tuesday', :email => 'bloody_tuesday@gamelayers.com',
                                                 :password => 'itsasekrit',
                                                 :password_confirmation => 'itsasekrit')
      user.save(false)
      UserLevel.create(:user_id => user.id, :primary_class => "destroyer")
      AbilityStatus.create(:user_id => user.id)
      Inventory.create(:owner_id => user.id, :owner_type => 'User')
      insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('#{user.id}', '#{role.id}', NOW(), NOW());" )
    end

    unless User.find(:first, :conditions => {:login => 'sasha_watkins'})
      user = User.new( :login => 'sasha_watkins', :email => 'sasha_watkins@gamelayers.com',
                                                 :password => 'itsasekrit',
                                                 :password_confirmation => 'itsasekrit')
      user.save(false)
      UserLevel.create(:user_id => user.id, :primary_class => "seer")
      AbilityStatus.create(:user_id => user.id)
      Inventory.create(:owner_id => user.id, :owner_type => 'User')
      insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('#{user.id}', '#{role.id}', NOW(), NOW());" )
    end

    unless User.find(:first, :conditions => {:login => 'ninefinder'})
      user = User.new( :login => 'ninefinder', :email => 'ninefinder@gamelayers.com',
                                                 :password => 'itsasekrit',
                                                 :password_confirmation => 'itsasekrit')
      user.save(false)
      UserLevel.create(:user_id => user.id, :primary_class => "pathmaker")
      AbilityStatus.create(:user_id => user.id)
      Inventory.create(:owner_id => user.id, :owner_type => 'User')
      insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('#{user.id}', '#{role.id}', NOW(), NOW());" )
    end

    unless User.find(:first, :conditions => {:login => 'thaddeus_esper'})
      user = User.new( :login => 'thaddeus_esper', :email => 'thaddeus_esper@gamelayers.com',
                                                 :password => 'itsasekrit',
                                                 :password_confirmation => 'itsasekrit')
      user.save(false)
      UserLevel.create(:user_id => user.id, :primary_class => "bedouin")
      AbilityStatus.create(:user_id => user.id)
      Inventory.create(:owner_id => user.id, :owner_type => 'User')
      insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('#{user.id}', '#{role.id}', NOW(), NOW());" )
    end

    # Thomas Hoggins was created in an earlier migration so lets just clean him up a bit and add the npc role
    user = User.find_by_login('thomas_hoggins')
    insert( "INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES ('#{user.id}', '#{role.id}', NOW(), NOW());" )
    user.user_level.primary_class = "benefactor"
    user.save
  end

  def self.down
    role = Role.find_by_name('npc')

    execute "DELETE FROM roles_users WHERE role_id = #{role.id}" unless role.nil?

    role.destroy unless role.nil?

    ["victoria_ash", "ninefinder", "thaddeus_esper", "sasha_watkins", "bloody_tuesday"].each do |i|
      u = User.find_by_login(i)
      u.destroy unless u.nil?
    end
  end
end
