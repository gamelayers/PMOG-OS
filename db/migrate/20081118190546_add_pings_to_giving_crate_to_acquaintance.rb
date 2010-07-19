class AddPingsToGivingCrateToAcquaintance < ActiveRecord::Migration
  def self.up
    p = Ping.create(:name => 'crate_acqu', :points => 5)
  end

  def self.down
    p = Ping.find_by_name('crate_acqu')
    p.destroy
  end
end
