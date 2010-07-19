class AddingInvitePings < ActiveRecord::Migration
  def self.up
    p = Ping.create(:name => 'invite_player', :points => 10)
  end

  def self.down
  end
end
