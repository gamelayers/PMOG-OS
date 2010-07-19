class AddAcquaintancePingPoints < ActiveRecord::Migration
  def self.up
    p = Ping.create(:name => 'make_acqu', :points => 5)
  end

  def self.down
    p = Ping.find_by_name('make_acqu')
    p.destroy
  end
end
