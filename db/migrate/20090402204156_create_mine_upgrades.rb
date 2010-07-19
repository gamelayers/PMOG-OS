class CreateMineUpgrades < ActiveRecord::Migration
  def self.up
    add_column :mines, :abundant, :boolean

    Upgrade.reset_column_information

    ever_mine_data = { :name => "Ever Mines",
      :url_name => 'ever_mine',
      :ping_cost => 5,
      :level => 10,
      :classpoints => 25,
      :pmog_class_id => PmogClass.find_by_name("Destroyers"),
      :short_description => "Ever Mines will stay on a website exploding once for each new player to come across them." }

    @ever_mines = Upgrade.find_by_url_name('ever_mine')
    @ever_mine.nil? ? Upgrade.create(ever_mine_data) : @ever_mine.update_attributes(ever_mine_data)

    stealth_mine_data = { :name => "Stealth Mines",
      :url_name => 'stealth_mine',
      :ping_cost => 10,
      :level => 8,
      :classpoints => 10,
      :pmog_class_id => PmogClass.find_by_name("Destroyers"),
      :short_description => "Stealth mines will not appear on the event stream unless a watchdog is blocking that site." }

    @stealth_mine = Upgrade.find_by_url_name('stealth_mine')
    @stealth_mine.nil? ? Upgrade.create(stealth_mine_data) : @stealth_mine.update_attributes(stealth_mine_data)

    stealth_crate_data = { :name => "Stealth Crates",
      :url_name => 'stealth_crate',
      :ping_cost => 10,
      :level => 8,
      :classpoints => 20,
      :pmog_class_id => PmogClass.find_by_name("Benefactors"),
      :short_description => "Stealth crates will not appear on the event stream." }

    @stealth_crate = Upgrade.find_by_url_name('stealth_crate')
    @stealth_crate.nil? ? Upgrade.create(stealth_crate_data) : @stealth_crate.update_attributes(stealth_crate_data)

    abundant_mine_data = { :name => "Abundant Mines",
      :url_name => 'abundant_mine',
      :ping_cost => 10,
      :level => 7,
      :damage => 15,
      :classpoints => 10,
      :pmog_class_id => PmogClass.find_by_name("Destroyers"),
      :short_description => "Abundant mines steal DP from your enemies." }

    @abundant_mine = Upgrade.find_by_url_name('abundant_mine')
    @abundant_mine.nil? ? Upgrade.create(abundant_mine_data) : @abundant_mine.update_attributes(abundant_mine_data)
  end

  def self.down
    remove_column :mines, :abundant
  end
end
