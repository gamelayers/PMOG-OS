class UpdateUpgradesAndTools < ActiveRecord::Migration
  def self.up

    @dog = Tool.find_by_name('watchdogs')
    @dog.level = 5
    @dog.icon_image = '/images/shared/tools/icon/watchdog-16.png'
    @dog.small_image = '/images/shared/tools/small/watchdogs.jpg'
    @dog.medium_image = '/images/shared/tools/medium/watchdogs.jpg'
    @dog.large_image = '/images/shared/tools/large/watchdogs.png'
    @dog.short_description = "Leave a Watchdog on any URL to prevent Destroyers from leaving mines there. These cost 40DP, but boy are they worth it! Watchdogs are available to Vigilante at Level 7 or above."
    @dog.cost = 40
    @dog.association_cost = 40, #i'm not positive how this field is used, so heres some temporary redundancy until i'm sure we dont need this
    @dog.save
    
    # lets clean house on these

    @abundant = Upgrade.find_by_url_name("give_dp")
    @abundant.short_description = 'If you modify your portals with 20 Pings to make your portals abundant, you will earn 2 datapoints for each player who takes your portal. '
    @abundant.long_description = 'This is a good chance to make some extra DP for yourself. Additionally, if the player decides to rate your portal you\'ll get another 1 DP.'
    @abundant.icon_image = '/images/shared/tools/icon/portal-16.png'
    @abundant.small_image = '/images/shared/tools/small/abundantportal.png'
    @abundant.medium_image = '/images/shared/tools/medium/abundantportal.png'
    @abundant.large_image = '/images/shared/tools/large/abundantportal.png'
    @abundant.level = 5
    @abundant.ping_cost = 20
    @abundant.save

    @puzzle = Upgrade.find_by_url_name("puzzle_crate")
    @puzzle.short_description = 'You can upgrade a crate with 20 Pings to make a Puzzle Crate. A Puzzle Crate protects the loot with a Question and Answer. Enter a question like, "What are shoats made of?" Then enter your answer, say, "Bacon".'
    @puzzle.long_description = 'Players who solve your Puzzle Crate will have to spell the answer exactly as you did. We don\'t look for capitalization but we look for character-matching. Remember this especially if the answer to a Puzzle Crate is a number.'
    @puzzle.icon_image = '/images/shared/tools/icon/crate-16.png'
    @puzzle.small_image = '/images/shared/tools/small/puzzlecrate.png'
    @puzzle.medium_image = '/images/shared/tools/medium/puzzlecrate.png'
    @puzzle.large_image = '/images/shared/tools/large/puzzlecrate.png'
    @puzzle.level = 7
    @puzzle.ping_cost = 20
    @puzzle.save

    @exploding = Upgrade.find_by_url_name("exploding_crate")
    @exploding.short_description = 'Upgrade a crate with 20 Pings and a mine to make an Exploding Crate! While another player thinks they\'re looting a perfectly safe crate, they\'ll actually be triggering your trap!'
    @exploding.long_description = 'You\'ll need to spend a mine as well as a crate in order to make an Exploding Crate, so this upgrade is a bit expensive. The look on your rival\'s face will make it totally worth it, though.'
    @exploding.icon_image = '/images/shared/tools/icon/crate-16.png'
    @exploding.small_image = '/images/shared/tools/small/explodingcrate.png'
    @exploding.medium_image = '/images/shared/tools/medium/explodingcrate.png'
    @exploding.large_image = '/images/shared/tools/large/explodingcrate.png'
    @exploding.level = 5
    @exploding.mine_cost = 1
    @exploding.damage = 10
    @exploding.ping_cost = 10
    @exploding.save


    #and now lets soft fix the imageresources while we're at it
    @crate = Tool.find_by_name("crates")
    @crate.icon_image = "/images/shared/tools/icon/crate-16.png"
    @crate.small_image = "/images/shared/tools/small/crates.jpg"
    @crate.medium_image = "/images/shared/tools/medium/crates.jpg"
    @crate.large_image = "/images/shared/tools/large/crates.png"
    @crate.save

    @lightpost = Tool.find_by_name("lightposts")
    @lightpost.icon_image = "/images/shared/tools/icon/lightpost-16.png"
    @lightpost.small_image = "/images/shared/tools/small/lightposts.jpg"
    @lightpost.medium_image = "/images/shared/tools/medium/lightposts.jpg"
    @lightpost.large_image = "/images/shared/tools/large/lightposts.png"
    @lightpost.save

    @mine = Tool.find_by_name("mines")
    @mine.icon_image = "/images/shared/tools/icon/mine-16.png"
    @mine.small_image = "/images/shared/tools/small/mines.jpg"
    @mine.medium_image = "/images/shared/tools/medium/mines.jpg"
    @mine.large_image = "/images/shared/tools/large/mines.png"
    @mine.save

    @portal = Tool.find_by_name("portals")
    @portal.icon_image = "/images/shared/tools/icon/portal-16.png"
    @portal.small_image = "/images/shared/tools/small/portals.jpg"
    @portal.medium_image = "/images/shared/tools/medium/portals.jpg"
    @portal.large_image = "/images/shared/tools/large/portals.png"
    @portal.save

    @nick = Tool.find_by_name("st_nicks")
    @nick.icon_image = "/images/shared/tools/icon/st_nick-16.png"
    @nick.small_image = "/images/shared/tools/small/st_nicks.jpg"
    @nick.medium_image = "/images/shared/tools/medium/st_nicks.jpg"
    @nick.large_image = "/images/shared/tools/large/st_nicks.png"
    @nick.save

    @armor = Tool.find_by_name("armor")
    @armor.icon_image = "/images/shared/tools/icon/armor-16.png"
    @armor.small_image = "/images/shared/tools/small/armor.jpg"
    @armor.medium_image = "/images/shared/tools/medium/armor.jpg"
    @armor.large_image = "/images/shared/tools/large/armor.png"
    @armor.save
  end

  def self.down
    #we don't really ever want to drop this, we're rebuilding the same records we delete within the up
  end
end
