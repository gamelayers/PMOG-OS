class UpdateTools < ActiveRecord::Migration
  
  @@short_descriptions = {
    :crates => 'Crates allow the safe storage of items across the web.',
    :lightposts => 'Lightposts light up the areas between web sites. They make visible connections that were dark before.',
    :mines => 'Mines catch users traveling by and self-destruct to create havoc.',
    :portals => 'Portals are a means of traveling from point to point online, guided by the player who puts them down.',
    :rockets => 'Rockets can be fired at walls built on websites.',
    :walls => 'Walls can be built around sites to prevent mines from being laid on them.',
    :st_nicks => 'St. Nicks attach to a user and abort one effort by that user to deploy either rockets or mines.',
    :armor => 'Armor prevents the player and their datapoints from damage.'
  }

  @@long_descriptions = {
    :crates => 'Crates can be bought in the Shoppe by players who rank Hoarder as one of their top three classes. Crates can store up to 1000 datapoints or 10 tools. For instance, you can store 500 datapoints and 5 tools in one crate. Crates can be stored inside of crates and count as one tool. Therefore if a player does not rank as a Hoarder, they may come across a Crate stored in a Crate on a website.',
    :lightposts => 'Lightposts are required to make Missions. Players who rank Pathmaker as one of their top three classes can buy Lightposts in the Shoppe. Otherwise, players can find them in Crates left on websites. In order to save a website for use in the Generator, players should deploy a Lighpost on it.',
    :mines => 'Mines can be bought in the Shoppe by any player who ranks Destroyer as one of their top three classes. Otherwise, players can find them in Crates left on websites.',
    :portals => 'Players have to rate their own portals either SFW or NSFW. If a player misrates their portal, they are barred from making another. Portals can be bought in the Shoppe by any player who ranks Seer as one of their top three classe. Otherwise, players can find them in Crates left on websites.',
    :rockets => 'Rules for Battle detail the exact play-by-play of these territorial encounters. Players who rank Grenadier as one of their top three classes can buy Rockets in the Shoppe. Otherwise, players can find Rockets in Crates left on websites.',
    :walls => 'Rules for Battle detail the exact play-by-play of these territorial encounters. Players who rank Riveter as one of their top three classes can buy Walls in the Shoppe. Otherwise, players can find Walls in Crates left on websites.',
    :st_nicks => 'Players who rank Vigilante as one of their top three classes can buy St. Nicks in the Shoppe. Otherwise, players can find St. Nicks left in Crates on websites.',
    :armor => 'One piece of Armor can sustain 5 mines worth of damage. Players who rank Bedouin as one of their top three classes can buy Armor in the Shopppe. Otherwise, they can find the Armor left in Crates on websites.'
   }

  @@small_images = {
    :lightposts => "/images/icons/tools/lightpost.jpg",
    :mines => "/images/icons/tools/mine.jpg",
    :portals => "/images/icons/tools/portal.jpg",
    :crates => "/images/icons/tools/crate.jpg",
    :walls => "/images/icons/tools/wall.jpg",
    :rockets => "/images/icons/tools/rocket.jpg",
    :armor => "/images/icons/tools/armor.jpg",
    :st_nicks => "/images/icons/tools/stnick.jpg"
  }
  
  @@large_images = {
    :lightposts => "/images/lightpost.jpg",
    :mines => "/images/mine.jpg",
    :portals => "/images/portal.jpg",
    :crates => "/images/crate.jpg",
    :walls => "/images/wall.jpg",
    :rockets => "/images/rocket.jpg",
    :armor => "/images/armor.jpg",
    :st_nicks => "/images/stnick.jpg"
  }

  def self.up
    add_column :tools, :short_description, :string
    add_column :tools, :long_description, :string
    add_column :tools, :small_image, :string
    add_column :tools, :large_image, :string

    Tool.find(:all).each do |tool|
      tool.short_description = @@short_descriptions[tool.name.to_sym]
      tool.long_description = @@long_descriptions[tool.name.to_sym]
      tool.small_image = @@small_images[tool.name.to_sym]
      tool.large_image = @@large_images[tool.name.to_sym]
      tool.save
    end

    remove_column :tools, :description
  end

  def self.down
    add_column :tools, :description, :string
    
    Tool.find(:all).each do |tool|
      tool.description = @@short_descriptions[tool.name.to_sym]
      tool.save
    end

    remove_column :tools, :short_description
    remove_column :tools, :long_description
    remove_column :tools, :small_image
    remove_column :tools, :large_image
  end
end
