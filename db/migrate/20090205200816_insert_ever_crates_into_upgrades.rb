class InsertEverCratesIntoUpgrades < ActiveRecord::Migration
  def self.up
    add_column :crate_upgrades, :ever_crate, :boolean

    Upgrade.reset_column_information
    
    ever_crate_data = { :name => "Ever Crate",
      :url_name => 'ever_crate',
      :ping_cost => 5,
      :level => 10,
      :classpoints => 25,
      :association_id => PmogClass.find_by_name("Benefactors"),
      :short_description => "Ever crates can be looted by a large number of people, one time each" }

    @ever_crates = Upgrade.find_by_url_name('ever_crate')
    if @ever_crates.nil?
      Upgrade.create(ever_crate_data)
    else
      @ever_crates.update_attributes(ever_crate_data)
    end
  end

  def self.down
    remove_column :crate_upgrades, :ever_crate
  end
end
