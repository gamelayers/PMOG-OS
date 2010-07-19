class CreatePmogClasses < ActiveRecord::Migration
  def self.up
    create_table :pmog_classes do |t|
      t.string :name
      t.string :short_description
      t.string :long_description
      t.string :small_image
      t.string :large_image
      t.timestamps 
    end
    
    PmogClass.create( :name => 'Hoarder', :short_description => 'Hoarders primarily use Crates to store datapoints and tools on sites all over the internetz. Hoarders carry the torch of Order.', :long_description => 'Hoarders are primarily concerned with the trade of material goods and use Crates more often than other tools. They probably also tend to take Missions made by other Hoarders. Faction: Order', :small_image => '/images/hoarder.jpg', :large_image => '/images/icons/classes/hoarder.jpg' )
    PmogClass.create( :name => 'Seer', :short_description => 'Seers use Portals to transport other players to parts unseen, places unknown, cats un-LOLed! Seers carry the torch of Chaos.', :long_description => 'Seers are agents of Chaos who enjoy long walks down dark Internet alleys, disrupting work days with funny or frightening links, and venturing into websites unseen. They use Portals more often than other tools and tend to take Missions made by other Seers. Faction: Chaos', :small_image => '/images/seer.jpg', :large_image => '/images/icons/classes/seer.jpg' )
    PmogClass.create( :name => 'Destroyers', :short_description => 'Destroyers use Mines to annoy other players and bring themselves great joy. Destroyers carry the torch of Chaos.', :long_description => "Destroyers take great joy in mining the shit out of the internets. They like to predict their rivals' travel plans and surreptitiously lay mines mines for them. They use Mines more often than other tools and tend to take Missions made by other Destroyers. Faction: Chaos", :small_image => '/images/destroyer.jpg', :large_image => '/images/icons/classes/destroyer.jpg' )
    PmogClass.create( :name => 'Pathmakers', :short_description => 'Pathmakers illuminated connections for other citizens of the digital world. Pathmakers carry the torch of Order.', :long_description => "Pathmakers revel in well-formatted pages, organized tags, and educational Missions. They use Lightposts more often than other tools and tend to take Missions made by other Pathmakers. Faction: Order", :small_image => '/images/pathmaker.jpg', :large_image => '/images/icons/classes/pathmaker.jpg' )
    PmogClass.create( :name => 'Vigilantes', :short_description => 'Vigilantes pursue the soldiers of Chaos throughout the PMOG system, planting St. Nicks everywhere they go. Vigilantes carry the torch of Order.', :long_description => 'Vigilantes pursue the soldiers of Chaos throughout the PMOG system. They abort the efforts of Destroyers, in particular, to mine websites and cost other players their precious data points. Vigilantes tend to use St. Nicks more often than other tools and take Missions made by other Vigilantes. Faction: Order', :small_image => '/images/vigilante.jpg', :large_image => '/images/icons/classes/vigilante.jpg' )
    PmogClass.create( :name => 'Riveters', :short_description => "Riveters construct walls to protect websites from the daring don'ts of other players. Riveters carry the torch of Order", :long_description => "Riveters like to thwart the efforts of Destroyers and Grenadiers by using Walls more than other tools. Faction: Order", :small_image => '/images/riveter.jpg', :large_image => '/images/icons/classes/riveter.jpg' )
    PmogClass.create( :name => 'Grenadiers', :short_description => "Grenadiers feed on destruction - they use rockets to blow holes in the walls of websites and make way for the ground troops: the Destroyers. Grenadiers carry the torch of Chaos.", :long_description => "Grenadiers feed on destruction. They use Rockets to blow holes in the walls of websites and make way for the ground troops: the Destroyers. Grenadiers also tend to take Missions made by other like-minded players. Faction: Chaos", :small_image => '/images/grenadier.jpg', :large_image => '/images/icons/classes/grenadier.jpg' )
    PmogClass.create( :name => 'Bedouins', :short_description => "Bedouins build personal armor for players, assuring that they will be safe from distraction and their friends might be, too. Bedouins carry the torch of Order.", :long_description => "Bedouins like to be protected from damage, and use Armor more often than other tools. They also tend to take Missions made by other Bedouins. Faction: Chaos", :small_image => '/images/bedouin.jpg', :large_image => '/images/icons/classes/bedouin.jpg' )
  end

  def self.down
    drop_table :pmog_classes
  end
end