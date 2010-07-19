class AddInviteBadges < ActiveRecord::Migration
  def self.up
        Badge.create( :name => "Inviting", :description => "5 invitations were accepted by players").save
        Badge.create( :name => "Alluring", :description => "10 invitations were accepted by players").save
        Badge.create( :name => "Magnetic", :description => "30 invitations were accepted by players").save
  end

  def self.down
  end
end
