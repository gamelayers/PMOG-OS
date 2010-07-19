class NewStewardRole < ActiveRecord::Migration
  def self.up
    Role.create(:name => 'steward')
  end

  def self.down
    Role.find_by_name('steward').destroy
  end
end
