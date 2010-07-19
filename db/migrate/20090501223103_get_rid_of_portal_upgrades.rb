class GetRidOfPortalUpgrades < ActiveRecord::Migration

  class PortalUpgrade < ActiveRecord::Base
    belongs_to :portal
  end

  def self.up
    add_column :portals, :abundant, :boolean, :default => false

    PortalUpgrade.all do |u|
      if u.give_dp.to_bool
        u.portal.abundant = true
        u.portal.save
      end
    end

    drop_table :mine_upgrades
    drop_table :portal_upgrades
    drop_table :st_nick_upgrades
    drop_table :lightpost_upgrades
  end

  def self.down
    create_table :portal_upgrades, :id => false do |t|
      t.string :id, :limit => 36
      t.string :portal_id, :limit => 36
      t.boolean :give_dp
      t.timestamps
    end

    Portal.all do |p|
      if p.abundant
        PortalUpgrade.create(:portal_id => p.id, :give_dp => true)
      end
    end

    remove_column :portals, :abundant
    
    create_table :mine_upgrades, :id => false do |t|
      t.string :id, :limit => 36
      t.string :mine_id, :limit => 36
      t.integer :damage
      t.timestamps
    end

    create_table :st_nick_upgrades, :id => false do |t|
      t.string :id, :limit => 36
      t.string :st_nick_id, :limit => 36
      t.boolean :ballistic
      t.timestamps
    end

    create_table :lightpost_upgrades, :id=> false do |t|
      t.string :id, :limit => 36
      t.string :lightpost_id, :limit => 36
      t.boolean :gravity_well
      t.timestamps
    end

  end
end
