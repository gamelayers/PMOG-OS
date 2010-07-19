class DefaultDeployedTools < ActiveRecord::Migration
  def self.up
    user = User.find_by_login('suttree')
    location = Location.find_or_create_by_url( Url.normalise('www.suttree.com') )

    # Mine
    user.mines.create( :location_id => location.id )

    # Portal
    destination = Location.find_or_create_by_url( Url.normalise('www.ecolocal.com') )
    user.portals.create( :location_id => location.id, :destination_id => destination.id )

    # Crate
    crate = user.crates.create( :location_id => location.id )
    
    # I have no idea what this is for. It breaks the ability to migrate down
    # and back up again with the subsequent changes to the inventories code,
    # so I've commented it out - duncan 17/02/09
    # Crate inventory
    #options = {}
    #options[:crate] = {}
    #options[:crate][:datapoints] = 100
    #crate.inventory.deposit(user, options)
  end

  def self.down
    # Changes to the models have made dropping these rows cleanly an impossible task.
    # Leaving them in doesn't do much harm, so thats our best option

    #user = User.find_by_login('suttree')
    #user.mines.destroy_all
    #user.portals.destroy_all

    #user.crates.destroy_all
    #user.save
  end
end
