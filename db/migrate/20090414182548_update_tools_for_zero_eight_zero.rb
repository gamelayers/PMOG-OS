class UpdateToolsForZeroEightZero < ActiveRecord::Migration
  def self.up

    Tool.reset_column_information
    Ability.reset_column_information
    Upgrade.reset_column_information
    
    # insert/update the stealth crate entry in :upgrades
    stealth_crate_data = Hash[:name => "Stealth Crates",
      :url_name => 'stealth_crate', 
      :short_description => "Too many people looting your crates? The location of your Crate will no longer appear in the events stream if you upgrade it to a Stealth Crate.",
      :long_description => "If you want your precious stores of wealth to be less easy to find, then the Stealth Crate Upgrade is your new best friend. Use this upgrade to hide Crates for specific players, or just to be sneaky. Beware of being too secretive, though, secrets can promote Chaos!",
      :icon_image => '/images/shared/tools/icon/stealth_crate-16.png',
      :small_image => '/images/shared/tools/small/stealth_crate.png',
      :medium_image => '/images/shared/tools/medium/stealth_crate.png',
      :large_image => '/images/shared/tools/large/stealth_crate.png',
      :level => 8,
      :ping_cost => 20,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 0,
      :portal_cost => 0,
      :st_nick_cost => 0, 
      :damage => 0,
      :classpoints => 15]
      
    @stealth_crate = Upgrade.find_by_url_name('stealth_crate')
	  @stealth_crate.update_attributes(stealth_crate_data) 
	  
	  # insert/update the stealth mine entry in :upgrades
    stealth_mine_data = Hash[:name => "Stealth Mines",
      :url_name => 'stealth_mine', 
      :short_description => "Has the events stream betrayed you? Is your seekrit mining ground no longer hallowed? Add a little stealth to your destruction: your Mines' location will be safe with Stealth Mines.",
      :long_description => "That is, of course, unless someone has put a Watchdog on that page. The Watchdog will rat you out to The Nethernet Events stream!",
      :icon_image => '/images/shared/tools/icon/stealth_mine-16.png',
      :small_image => '/images/shared/tools/small/stealth_mine.png',
      :medium_image => '/images/shared/tools/medium/stealth_mine.png',
      :large_image => '/images/shared/tools/large/stealth_mine.png',
      :level => 8,
      :ping_cost => 20,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 0,
      :portal_cost => 0,
      :st_nick_cost => 0, 
      :damage => 0,
      :classpoints => 15]
      
    @stealth_mine = Upgrade.find_by_url_name('stealth_mine')
	  @stealth_mine.update_attributes(stealth_mine_data) 

   # insert/update the ballistic st. nicks entry in :upgrades
    ballistic_nick_data = Hash[:name => "Ballistic St. Nick",
      :url_name => 'ballistic_nick', 
      :short_description => "Common St. Nicks target Mines and Grenades.  Ballistic St. Nicks target the wielder of Mines and Grenades. Once upgraded with Ballistic energy, these babies will totally destroy the Armor of their target, or deliver their target a little righteous pain. ",
      :long_description => "As with common St. Nicks, the sensor in this device is only activated by a player attempting to lay a Mine or throw a Grenade. The Ballistic St. Nick will still do some damage to a player who is not wearing armor, but the metals in the Armor amplify the damage of Ballistic energy and even fully charged Armor will be blown away by a single Ballistic St. Nick. ",
      :icon_image => '/images/shared/tools/icon/ballistic_nick-16.png',
      :small_image => '/images/shared/tools/small/ballistic_nick.png',
      :medium_image => '/images/shared/tools/medium/ballistic_nick.png',
      :large_image => '/images/shared/tools/large/ballistic_nick.png',
      :level => 5,
      :dp_cost => 0,
      :ping_cost => 15,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 0,
      :portal_cost => 0,
      :st_nick_cost => 0, 
      :damage => 5,
      :classpoints => 15]
      
    @ballistic_nick = Upgrade.find_by_url_name('ballistic_nick')
	  @ballistic_nick.update_attributes(ballistic_nick_data) 
	  	  
	  # insert/update the abundant mines entry in :upgrades
    abundant_mine_data = Hash[:name => "Abundant Mines",
      :url_name => 'abundant_mine', 
      :short_description => "Abundant Mines give Datapoints to the Destroyer who upgraded the Mine. If you're tired of watching DP fall from the pockets of your victims and finding yourself unable to cash in on it, this is the upgrade for you. ",
      :long_description => "Just for kicks, Abundant Mines even do a little more damage than common Mines. And yes, the DP that you earn from these Abundant Mines comes from the player you mined. Devious!",
      :icon_image => '/images/shared/tools/icon/abundant_mine-16.png',
      :small_image => '/images/shared/tools/small/abundant_mine.png',
      :medium_image => '/images/shared/tools/medium/abundant_mine.png',
      :large_image => '/images/shared/tools/large/abundant_mine.png',
      :level => 7,
      :dp_cost => 0,
      :ping_cost => 20,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 0,
      :portal_cost => 0,
      :st_nick_cost => 0, 
      :damage => 15,
      :classpoints => 15]
      
    @abundant_mine = Upgrade.find_by_url_name('abundant_mine')
	  @abundant_mine.update_attributes(abundant_mine_data) 

	  # insert/update the puzzle post entry in :upgrades
    puzzle_post_data = Hash[:name => "Puzzle Posts",
      :url_name => 'puzzle_post', 
      :short_description => "Puzzle Posts stop a player from proceeding through a Mission until they have answered a question. ",
      :long_description => "These questions-and-answers must match word for word. If your question is \"Is there a mine on the next page?\" and your answer is \"Yes.\" then the only acceptable answers will be exactly \"YES.\", \"yes.\", \"yEs.\", \"Yes.\", and so on.",
      :icon_image => '/images/shared/tools/icon/puzzle_post-16.png',
      :small_image => '/images/shared/tools/small/puzzle_post.png',
      :medium_image => '/images/shared/tools/medium/puzzle_post.png',
      :large_image => '/images/shared/tools/large/puzzle_post.png',
      :level => 7,
      :dp_cost => 0,
      :ping_cost => 200,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 0,
      :portal_cost => 0,
      :st_nick_cost => 0, 
      :damage => 0,
      :classpoints => 100]
      
    @puzzle_post = Upgrade.find_by_url_name('puzzle_post')
	  @puzzle_post.update_attributes(puzzle_post_data) 	 
	 	 
	  # insert/update the create skeleton key entry in :abilities
    create_skeleton_key_data = Hash[:name => "Create a Skeleton Key",
      :url_name => 'create_skeleton_key', 
      :short_description => "Crafted by Seers from their knowledge of transmission and transgression, Skeleton Keys unlock Puzzle Crates and Puzzle Posts.",
      :long_description => "Skeleton Keys can only be created by Seers, but can be used by any player that can convince a Seer to give one up. Skeleton Keys will unlock Puzzle Crates, revealing the answer to the riddle, and yielding all the contents inside.  Skeleton Keys will also unlock Puzzle Posts, but the answers to those riddles can not yet be gleaned with this Seer technology.",
      :icon_image => '/images/shared/tools/icon/skeleton_key-16.png',
      :small_image => '/images/shared/tools/small/skeleton_key.png',
      :medium_image => '/images/shared/tools/medium/skeleton_key.png',
      :large_image => '/images/shared/tools/large/skeleton_key.png',
      :level => 10,
      :dp_cost => 100,
      :ping_cost => 50,
      :classpoints => 15]
      
    @create_skeleton_key = Ability.find_by_url_name('create_skeleton_key')
	  @create_skeleton_key.update_attributes(create_skeleton_key_data)  
	   
	  # insert/update the vengeance entry in :abilities
    vengeance_data = Hash[:name => "Vengeance",
      :url_name => 'vengeance', 
      :short_description => "High Level Bedouins can enhance their Armor with Vengeance. If you choose to use this ability, your armor will reflect damage back onto your attacker!",
      :long_description => "With each use, the Vengeance present on any piece of Armor will degrade with time. Watch your Armor to know how many charges you have left.  You will be automatically charged a few Pings each time Vengeance is triggered.",
      :level => 15,
      :dp_cost => 0,
      :ping_cost => 20,
      :percentage => 50,
      :classpoints => 25]
      
    @vengeance = Ability.find_by_url_name('vengeance')
	  @vengeance.update_attributes(vengeance_data)
  end

  def self.down
  end
end
