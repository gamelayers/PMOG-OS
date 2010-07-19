class FixingToolsAndClasses < ActiveRecord::Migration
  @@tool_long_descriptions = {
    :crates => 'Crates can be bought in the Shoppe by players who rank Hoarder as one of their top three classes. Crates can store up to 1000 datapoints or 10 tools. For instance, you can store 500 datapoints and 5 tools in one crate. Crates can be stored inside of crates and count as one tool. Therefore if a player does not rank as a Hoarder, they may come across a Crate stored in a Crate on a website.',
    :lightposts => 'Lightposts are required to make Missions. Players who rank Pathmaker as one of their top three classes can buy Lightposts in the Shoppe. Otherwise, players can find them in Crates left on websites. In order to save a website for use in the Generator, players should deploy a Lighpost on it.',
    :mines => 'Mines can be bought in the Shoppe by any player who ranks Destroyer as one of their top three classes. Otherwise, players can find them in Crates left on websites.',
    :portals => 'Players have to rate their own portals either SFW or NSFW. If a player misrates their portal, they are barred from making another. Portals can be bought in the Shoppe by any player who ranks Seer as one of their top three classe. Otherwise, players can find them in Crates left on websites.',
    :rockets => 'Rules for Battle detail the exact play-by-play of these territorial encounters. Players who rank Grenadier as one of their top three classes can buy Rockets in the Shoppe. Otherwise, players can find Rockets in Crates left on websites.',
    :walls => 'Rules for Battle detail the exact play-by-play of these territorial encounters. Players who rank Riveter as one of their top three classes can buy Walls in the Shoppe. Otherwise, players can find Walls in Crates left on websites.',
    :st_nicks => 'Players who rank Vigilante as one of their top three classes can buy St. Nicks in the Shoppe. Otherwise, players can find St. Nicks left in Crates on websites.',
    :armor => 'One piece of Armor can sustain 5 mines worth of damage. Players who rank Bedouin as one of their top three classes can buy Armor in the Shopppe. Otherwise, they can find the Armor left in Crates on websites.'
   }


   @@class_long_descriptions = {
     :hoarder => 'Hoarders are primarily concerned with the trade of material goods and use Crates more often than other tools. They probably also tend to take Missions made by other Hoarders. Faction: Order', 
     :seer => 'Seers are agents of Chaos who enjoy long walks down dark Internet alleys, disrupting work days with funny or frightening links, and venturing into websites unseen. They use Portals more often than other tools and tend to take Missions made by other Seers. Faction: Chaos', 
     :destroyers => "Destroyers take great joy in mining the shit out of the internets. They like to predict their rivals' travel plans and surreptitiously lay mines mines for them. They use Mines more often than other tools and tend to take Missions made by other Destroyers. Faction: Chaos", 
     :pathmakers => "Pathmakers revel in well-formatted pages, organized tags, and educational Missions. They use Lightposts more often than other tools and tend to take Missions made by other Pathmakers. Faction: Order", 
     :vigilantes => 'Vigilantes pursue the soldiers of Chaos throughout the PMOG system. They abort the efforts of Destroyers, in particular, to mine websites and cost other players their precious data points. Vigilantes tend to use St. Nicks more often than other tools and take Missions made by other Vigilantes. Faction: Order', 
     :riviters => "Riveters like to thwart the efforts of Destroyers and Grenadiers by using Walls more than other tools. Faction: Order", 
     :grenadiers => "Grenadiers feed on destruction. They use Rockets to blow holes in the walls of websites and make way for the ground troops: the Destroyers. Grenadiers also tend to take Missions made by other like-minded players. Faction: Chaos", 
     :bedouins => "Bedouins like to be protected from damage, and use Armor more often than other tools. They also tend to take Missions made by other Bedouins. Faction: Chaos"
   }

  def self.up
    # Long description for tools and classes needs to be text, not a 255 string
    remove_column :tools, :long_description
    add_column :tools, :long_description, :text
    remove_column :pmog_classes, :long_description
    add_column :pmog_classes, :long_description, :text
    add_column :pmog_classes, :history, :text
    add_column :tools, :history, :text

    Tool.find(:all).each do |tool|
      tool.long_description = @@tool_long_descriptions[tool.name.to_sym]
      tool.save
    end

    PmogClass.find(:all).each do |pmog_class|
      pmog_class.long_description = @@class_long_descriptions[pmog_class.name.to_sym]
      pmog_class.save
    end

  end

  def self.down
    # Restore them to their broken state
    remove_column :tools, :long_description
    add_column :tools, :long_description, :string
    remove_column :pmog_classes, :long_description
    add_column :pmog_classes, :long_description, :string
    remove_column :pmog_classes, :history
    remove_column :tools, :history
  end
end
