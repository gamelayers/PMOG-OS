class RenamePmogUserToSystemUser < ActiveRecord::Migration
  def self.up
    u = User.find_by_login 'pmog'
    u.login = 'TheNethernet'
    u.save(false)
  end

  def self.down
    u = User.find_by_login 'TheNethernet'
    u.login = 'pmog'
    u.save(false)
  end
end