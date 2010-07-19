class UpdateGuideForNethernetLaunch < ActiveRecord::Migration
  def self.up

    PmogClass.reset_column_information
    Tool.reset_column_information
    Ability.reset_column_information
    Upgrade.reset_column_information

    # insert/update the lightpost entry in :tools
    lightposts_data = Hash[#:name => "Lightposts",
#      :url_name => 'lightposts',
      :short_description => "Lightposts light up the areas between web sites. They make visible connections that were dark before.",
      :long_description => "Lightposts are required to make <a href=\"/missions/\">Missions</a>. Players who rank <a href=\"/codex/associations/pathmakers\">Pathmaker</a> as one of their top three associations can buy lightposts in the Shoppe. Otherwise, players can find Lightposts in crates left on websites. In order to save a website for use in the Generator, players should deploy a lighpost on it - much like bookmarking a site. Lightposts may be gifted between players by the gifter leaving lightposts in crates on the recipient's profile. ",
      :level => 1,
      :cost => 5,
      :classpoints => 10]

    @lightposts = Tool.find_by_name('lightposts')
    @lightposts.update_attributes(lightposts_data)

    # insert/update the mine entry in :tools
    mines_data = Hash[#:name => "Mines",
#     :url_name => 'mines',
      :short_description => "Mines catch users traveling by and self-destruct to create havoc.",
      :long_description => "Mines can be bought in the Shoppe by any player who ranks <a href=\"/codex/associations/destroyers\">Destroyer</a> as one of their top three associations. Otherwise, players can find them in crates left on websites. Mines can be gifted by a player deploying a crate stuffed with Mines on another player's profile.",
      :level => 1,
      :cost => 20,
      :damage => 10,
      :classpoints => 5]

    @mines = Tool.find_by_name('mines')
    @mines.update_attributes(mines_data)

    # insert/update the portals entry in :tools
    portals_data = Hash[#:name => "Portals",
#     :url_name => 'portals',
     :short_description => "Portals are a means of traveling from point to point online, guided by the player who puts them down.",
     :long_description => "Players have to rate their own portals either SFW or NSFW. Portals can be bought in the Shoppe by any player who ranks <a href=\"/codex/associations/seers\">Seer</a> as one of their top three associations. Otherwise, players can find them in crates left on websites. Portals may also be directly gifted from player to player if placed inside a crate on a player profile. ",
     :level => 1,
     :charges => 50,
     :cost => 25,
     :classpoints => 15]

    @portals = Tool.find_by_name('portals')
    @portals.update_attributes(portals_data)

    # insert/update the crates entry in :tools
    crates_data = Hash[#:name => "Crates",
#      :url_name => 'crates',
      :short_description => "Crates allow the safe storage of items across the web.",
      :long_description => "Crates can store up to 1000 datapoints, 500 Pings, and 10 tools. Crates can be stored inside of crates. Crates can be upgraded to be an <a href=\"/guide/upgrades/exploding_crate\">Exploding Crate</a>, a <a href=\"/guide/upgrades/puzzle_crate\">Puzzle Crate</a>, or an <a href=\"/guide/upgrades/ever_crate\">Ever Crate</a>.",
      :level => 3,
      :cost => 10,
      :classpoints => 15]

    @crates = Tool.find_by_name('crates')
    @crates.update_attributes(crates_data)

    # insert/update the st_nicks entry in :tools
    st_nicks_data = Hash[#:name => "St. Nicks",
#     :url_name => 'st_nicks',
      :short_description => "St. Nicks attach to a player and abort one mine or grenade left by that player.",
      :long_description => "Use St. Nicks to get revenge for damage dealt or to provoke Destroyers into attacking you. If you're looking for the criminal set, start with the Events feed. Any player can have up to 5 St. Nicks attached to them at a time, but no more.",
      :level => 1,
      :cost => 20,
      :classpoints => 10]

    @st_nicks = Tool.find_by_name('st_nicks')
    @st_nicks.update_attributes(st_nicks_data)

    # insert/update the armor entry in :tools
    armor_data = Hash[#:name => "Armor",
#      :url_name => 'armor',
      :short_description => "Armor prevents the player and their datapoints from damage.",
      :long_description => "One piece of armor can absorb 3 hits of damage from a mine or a grenade.",
      :level => 1,
      :charges => 3,
      :cost => 25,
      :classpoints => 15]

    @armor = Tool.find_by_name('armor')
    @armor.update_attributes(armor_data)

    # insert/update the watchdogs entry in :tools
    watchdogs_data = Hash[#:name => "Watchdogs",
#      :url_name => 'watchdogs',
      :short_description => "Leave a Watchdog on any URL to prevent Destroyers from leaving mines there.",
      :long_description => "Watchdogs are a great way to protect your favorite sites and to catch whomever is attacking them.",
      :level => 7,
      :cost => 20,
      :classpoints => 15]

    @watchdogs = Tool.find_by_name('watchdogs')
    @watchdogs.update_attributes(watchdogs_data)

    # insert/update the grenades entry in :tools
    grenades_data = Hash[#:name => "Grenades",
#      :url_name => 'grenades',
      :short_description => "Throw a grenade at another player to deal damage.",
      :long_description => "Grenades are used to damage another player in real time.  When you throw a grenade at someone, the next time that player moves to a new web page, it will explode, dealing damage.  Grenades can be stopped by St Nicks, and blocked or dodged by Bedouin. If a player is offline, they can accumulate up to 5 Grenades on their person that will detonate when they begin crossing domains again.",
      :level => 3,
      :cost => 20,
      :damage => 10,
      :classpoints => 10]

    @grenades = Tool.find_by_name('grenades')
    @grenades.update_attributes(grenades_data)

    # insert/update the abundant portals entry in :upgrades
    abundant_portals_data = Hash[:name => "Abundant Portals",
#      :url_name => 'give_dp',
      :short_description => "If you modify your portals with 20 Pings to make your portals abundant, you will earn 2 datapoints for each player who takes your portal.",
      :long_description => "This is a good chance to make some extra DP for yourself. Additionally, if the player decides to rate your portal you'll get another 1 DP.",
      :level => 5,
      :dp_cost => 0,
      :ping_cost => 20,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 0,
      :portal_cost => 0,
      :st_nick_cost => 0,
      :damage => 0,
      :classpoints => 20]

    @abundant_portals = Upgrade.find_by_url_name('give_dp')
    @abundant_portals.update_attributes(abundant_portals_data)

    # insert/update the exploding crates entry in :upgrades
    exploding_crate_data = Hash[:name => "Exploding Crates",
#      :url_name => 'exploding_crate',
      :short_description => "Upgrade a crate with 20 Pings and a mine to make an Exploding Crate! While another player thinks they're looting a perfectly safe crate, they'll actually be triggering your trap!",
      :long_description => "You'll need to spend a mine as well as a crate in order to make an Exploding Crate, so this upgrade is a bit expensive. The look on your rival's face will make it totally worth it, though. And because these mines have been hidden in crates, St. Nicks will not prevent against Exploding Crates. ",
      :level => 5,
      :dp_cost => 0,
      :ping_cost => 20,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 1,
      :portal_cost => 0,
      :st_nick_cost => 0,
      :damage => 10,
      :classpoints => 15]

    @exploding_crate = Upgrade.find_by_url_name('exploding_crate')
    @exploding_crate.update_attributes(exploding_crate_data)
       
    # insert/update the puzzle crates entry in :upgrades
    puzzle_crate_data = Hash[:name => "Puzzle Crates",
#      :url_name => 'puzzle_crate',
      :short_description => "You can upgrade a crate with 20 Pings to make a Puzzle Crate. A Puzzle Crate protects the loot with a Question and Answer. Enter a question like, \"What are shoats made of?\" Then enter your answer, say, \"Bacon\".",
      :long_description => "Players who solve your Puzzle Crate will have to spell the answer exactly as you did. We don't look for capitalization but we look for character-matching. Remember this especially if the answer to a Puzzle Crate is a number.",
      :level => 7,
      :dp_cost => 0,
      :ping_cost => 20,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 0,
      :portal_cost => 0,
      :st_nick_cost => 0,
      :damage => 0,
      :classpoints => 25]

    @puzzle_crate = Upgrade.find_by_url_name('puzzle_crate')
    @puzzle_crate.update_attributes(puzzle_crate_data)

    # insert/update the ever crates entry in :upgrades
    ever_crate_data = Hash[:name => "Ever Crates",
#      :url_name => 'ever_crate',
      :short_description => "Ever Crates can be looted by a large number of people, one time each.",
      :long_description => "When you first stash an Ever Crate on a site, you'll be charged for all the loot that you're putting in there at that time.",
      :level => 10,
      :dp_cost => 0,
      :ping_cost => 20,
      :armor_cost => 0,
      :crate_cost => 0,
      :lightpost_cost => 0,
      :mine_cost => 0,
      :portal_cost => 0,
      :st_nick_cost => 0,
      :damage => 0,
      :classpoints => 25]

    @ever_crate = Upgrade.find_by_url_name('ever_crate')
    @ever_crate.update_attributes(ever_crate_data)        
       
    # insert/update the dodge and disarm entry in :abilities
    disarm_data = Hash[:name => "Dodge and Disarm",
#      :url_name => 'disarm',
      :short_description => "Stop an attack and add the tool used against you to your inventory.",
      :long_description => "Dodge and disarm works against a grenade attack or a mine attack. This ability costs Pings, so you can turn it off from the toolbar if you'd rather not spend your Pings collecting weapons.",
      :level => 12,
      :dp_cost => 0,
      :ping_cost => 15,
      :classpoints => 20]

    @disarm = Ability.find_by_url_name('disarm')
    @disarm.update_attributes(disarm_data)
       
    # insert/update the dodge entry in :abilities
    dodge_data = Hash[:name => "Dodge",
#      :url_name => 'dodge',
      :short_description => "Dodge a mine after setting it off, avoiding all damage.",
      :long_description => "Dodge works against a grenade attack or a mine attack. This ability costs Pings, so you can turn it off from the toolbar if you'd rather not spend your Pings avoiding damage.",
      :level => 3,
      :dp_cost => 0,
      :ping_cost => 10,
      :percentage => 10,
      :classpoints => 15]

    @dodge = Ability.find_by_url_name('dodge')
    @dodge.update_attributes(dodge_data)

    # insert/update the dp cards entry in :abilities
    giftcard_data = Hash[:name => "DP Cards",
#      :url_name => 'giftcard',
      :short_description => "Play a DP Card and leave 10 DP on a site for another player to find. ",
      :long_description => "Playing DP Cards is a simple way to show that you like something.",
      :level => 1,
      :dp_cost => 10,
      :ping_cost => 0,
      :classpoints => 5]

    @giftcard = Ability.find_by_url_name('giftcard')
    @giftcard.update_attributes(giftcard_data)

  
    # insert/update the Benefactors entry in :classes
    benefactors_data = Hash[#:name => "Benefactors",
#      :name => 'Benefactors',
      :short_description => "Benefactors are known for their gracious manner and generous personalities. They strive to get along with everyone and are part of the faction of Order.",
      :long_description => "<div class=\"copyTop\"><h2>Gracious & Generous</h2> <p>Benefactors are known for their gracious manner and generous personalities. They strive to get along with everyone and are part of the faction of Order.</p>

<div class=\"width275\">

<a href=\"/guide/abilities/giftcard\"><img class=\"thumb\" src=\"/images/shared/tools/small/dp_cards.jpg\" height=\"50\" alt=\"DP Card\" width=\"50\" /></a>

<h4><a href=\"/guide/abilities/giftcard\">DP Card Ability</a></h4>

<p>Benefactors use the \"awsm!\" button in the toolbar to leave DP Cards on sites they like. Since using DP Cards is an ability, you'll never have to buy them in the Shoppe. Each DP Card is worth 10 datapoints. </p>

<a href=\"/guide/abilities/giftcard\"><img class=\"thumb\" src=\"/images/shared/tools/small/crates.jpg\" height=\"50\" alt=\"Crate\" width=\"50\" /></a>

<h4><a href=\"/codex/tools/crates\">Crates</a></h4>

<p>Crates are tool available to Level 3 Benefactors. You can store up to 10 tools, 1000 Datapoints, and 500 Pings in one crate. Crates are great way to trade loot with other players.</p>

<a href=\"/guide/lore/anabundantlife/\"><img class=\"thumb\" src=\"/images/guide/characters/thaddeusesper-50.png\" height=\"50\" alt=\"crate\" width=\"50\" /></a>

<h4><a href=\"/guide/lore/anabundantlife/\">\"An Abundant Life: The

Crate\"</a></h4>

<p>by Benefactors for Beneficial Behavior</p>

</div>

<div class=\"width20\"></div>

<div class=\"width275\">

<a href=\"/guide/upgrades/puzzle_crates\"><img class=\"thumb\" src=\"/images/shared/tools/small/puzzlecrate.png\" height=\"50\" alt=\"Puzzle Crate\" width=\"50\" /></a>

<h4><a href=\"/guide/upgrades/puzzle_crate\">Puzzle Crate Upgrade</a></h4>

<p>You can upgrade a crate with 10 Pings to make a Puzzle Crate. A Puzzle Crate protects the loot with a Question and Answer. Enter a question like, \"What are shoats made of?\" Then enter your answer, say, \"Bacon\".</p>

<a href=\"/guide/characters/thomas_hoggins_esq\"><img class=\"thumb\" src=\"/images/guide/characters/thomashoggins-50.png\" height=\"50\" alt=\"Thomas P. Hoggins, Esq.\" width=\"50\" /></a>

<h4><a href=\"/guide/characters/thomas_hoggins_esq\">Thomas P. Hoggins, Esq.</a></h4>

<p>Sir Thomas is the Benefactor of Benefactors. The richest man ever to travel through the Nethernet he is known for his generosity and desire for order. <a href=\"/guide/characters/thomas_hoggins_esq\">Learn More</a></p>

</div>"]

    @benefactors = PmogClass.find_by_name('Benefactors')
    @benefactors.update_attributes(benefactors_data)   
       
    # insert/update the Seers entry in :classes
    seers_data = Hash[#:name => "Seers",
#      :name => 'Seers',
      :short_description => "Seers find strange new places on the web and transport other players to those destinations. They're the pranksters of the web that seek out parts unseen, places unknown, cats un-LOLed!",
      :long_description => "<div class=\"copyTop\"><h2>The pranksters of the web</h2> <p>Seers find strange new places on the web and transport other players to those destinations. They're the pranksters of the web that seek out parts unseen, places unknown, cats un-LOLed!</p></div>

<div class=\"width275\">

<a href=\"/guide/tools/portals\"><img class=\"thumb\" src=\"/images/shared/tools/small/portals.jpg\" height=\"50\" alt=\"DP Card\" width=\"50\" /></a>

<h4><a href=\"/guide/tools/portals\">Portals</a></h4>

<p>Seers use Portals to send other players from site to site without knowledge of their destination.</p>

<a href=\"/guide/upgrades/give_dp\"><img class=\"thumb\" src=\"/images/shared/tools/small/abundantportal.png\" height=\"50\" alt=\"Abundant Portals\" width=\"50\" /></a>

<h4><a href=\"/guide/upgrades/give_dp\">Abundant Portal Upgrade</a></h4>

<p>At Level 5, Seers can upgrade their Portals so that they earn 2 DP for each player who takes it.</p>

</div>

<div class=\"width20\"></div>

<div class=\"width275\">

<a href=\"/guide/lore/amemoryofportals/\"><img class=\"thumb\" src=\"/images/shared/dressing/seer-50.png\" height=\"50\" alt=\"Professor Thaddeus Esper\" width=\"50\" /></a>

<h4><a href=\"/guide/lore/amemoryofportals/\">\"A Memory of

Portals\"</a></h4>

<p>by Seers of Erractic Compulsion</p>

<a href=\"/guide/characters/sasha_watkins\"><img class=\"thumb\" src=\"/images/guide/characters/sashawatkins-50.png\" height=\"50\" alt=\"Sasha Watkins\" width=\"50\" /></a>

<h4><a href=\"/guide/characters/sasha_watkins\">Sasha Watkins</a></h4>

<p>Sasha is a Seer. However, due to overexposure to Portals and a propensity to want to connect even the most distant regions of the Nethernet with one another, some find her mad. <a href=\"/guide/characters/sasha_watkins\">Learn More</a></p>

</div> "]

    @seers = PmogClass.find_by_name('Seers')
    @seers.update_attributes(seers_data)   
       
    # insert/update the Destroyers entry in :classes
    destroyers_data = Hash[#:name => "Destroyers",
#      :name => 'Destroyers',
      :short_description => "Destroyers annoy other players and bring themselves great joy. Destroyers are members of the faction of Chaos.",
      :long_description => "<div class=\"true\"><h2>KA-POW!</h2><p>Destroyers annoy other players and bring themselves great joy. Destroyers are members of the faction of Chaos.</p></div>

<div class=\"width275\">

<a href=\"/guide/tools/mines\"><img class=\"thumb\" src=\"/images/shared/tools/small/mines.jpg\" height=\"50\" alt=\"A Mine\" width=\"50\" /></a>

<h4><a href=\"/guide/tools/mines\">Mines</a></h4>

<p>Destroyers use the \"attack!\" button on the toolbar to leave Mines all over The Nethernet.</p>

<a href=\"/guide/upgrades/exploding_crates\"><img class=\"thumb\" src=\"/images/shared/tools/small/explodingcrate.png\" height=\"50\" alt=\"Exploding Crate\" width=\"50\" /></a>

<h4><a href=\"/guide/upgrades/exploding_crates\">Exploding Crate Upgrade</a></h4>

<p>At Level 5 Destroyers can upgrade Crates by spending 10 Pings and a Mine to make an Exploding Crate. Quite the hack, the Exploding Crate looks just like a regular, loot-filled crate until...</p>

</div>

<div class=\"width20\"></div>

<div class=\"width275\">

<a href=\"/guide/characters/bloody_tuesday\"><img class=\"thumb\" src=\"/images/guide/characters/bloodytuesday-50.png\" height=\"50\" alt=\"Bloody Tuesday\" width=\"50\" /></a>

<h4><a href=\"/guide/characters/bloody_tuesday\">Bloody Tuesday</a></h4>

<p>Bloody Tuesday the Destroyer, may very well be the most notorious of this group of characters. Players know Tuesdays bring an onslaught of chaos from the hand of Bloody Tuesday. <a href=\"/guide/characters/bloody_tuesday\">Learn More</a></p>

<a href=\"/guide/lore/minehistory/\"><img class=\"thumb\" src=\"/images/shared/tools/small/mines.jpg\" height=\"50\" alt=\"mines\" width=\"50\" /></a>

<h4><a href=\"/guide/lore/minehistory/\">\"The Mine: A Story of

Betrayal and Loss\"</a></h4>

<p>by Destroyers for a Chaotic Tomorrow</p>

</div>"]

    @destroyers = PmogClass.find_by_name('Destroyers')
    @destroyers.update_attributes(destroyers_data)

    # insert/update the Pathmakers entry in :classes
    pathmakers_data = Hash[#:name => "Pathmakers",
#      :name => 'Pathmakers',
      :short_description => "Using Lightposts, Pathmakers illuminate connections for other citizens of the digital world. Pathmakers carry the torch of Order.",
      :long_description => "<div class=\"copyTop\">

<h2>A Light in the Dark</h2><p>Using <a href=\"/guide/tools/lightposts/\">Lightposts</a>, Pathmakers illuminate connections for other citizens of the digital world. Pathmakers carry the torch of Order.

</p></div>

<div class=\"width275\">

<a href=\"/guide/tools/lightposts\"><img class=\"thumb\" src=\"/images/shared/tools/small/lightposts.jpg\" height=\"50\" alt=\"Lightposts\" width=\"50\" /></a>

<h4><a href=\"/guide/tools/lightposts\">Lightposts</a></h4>

<p>Pathmakers use lightposts to save URLs and make Missions.</p>

<a href=\"/guide/lore/tothelightpost/\"><img class=\"thumb\" src=\"/images/shared/tools/small/lightposts.jpg\" height=\"50\" alt=\"lightpost\" width=\"50\" /></a>

<h4><a href=\"/guide/lore/tothelightpost/\">\"To The Lightpost\"</a></h4>

<p>by

the Pathmakers Alliance of Remembrance</p>

</div>

<div class=\"width20\"></div>

<div class=\"width275\">

<a href=\"/guide/characters/ninefinder\"><img class=\"thumb\" src=\"/images/guide/characters/ninefinder-50.png\" height=\"50\" alt=\"PSMK9, aka Ninefinder\" width=\"50\" /></a>

<h4><a href=\"/guide/characters/ninefinder\">PSMK9, aka Ninefinder</a></h4>

<p>Ninefinder is a Pathmaking robot. His mission populate the Nethernet with random bits of knowledge from his endless travels through the Internets. <a href=\"/guide/characters/ninefinder\">Learn More</a></p>

</div>"]

    @pathmakers = PmogClass.find_by_name('Pathmakers')
    @pathmakers.update_attributes(pathmakers_data)   
       
    # insert/update the Vigilantes entry in :classes
    vigilantes_data = Hash[#:name => "Vigilantes",
#      :name => 'Vigilantes',
      :short_description => "Vigilantes pursue the soldiers of Chaos throughout the PMOG system. Yet because they continue the cycle of violence, Vigilantes are part of the Faction of Chaos.",
      :long_description => "<div class=\"copyTop\">

<h2>A Different Kind of Justice</h2><p>Vigilantes pursue the soldiers of Chaos throughout the PMOG system. Yet because they continue the cycle of violence, Vigilantes are part of the Faction of Chaos.</p></div>

<div class=\"width275\">

<a href=\"/guide/tools/st_nicks\"><img class=\"thumb\" src=\"/images/shared/tools/small/st_nicks.jpg\" height=\"50\" alt=\"St. Nicks\" width=\"50\" /></a>

<h4><a href=\"/guide/tools/st_nicks\">St. Nicks</a></h4>

<p>Vigilante use St. Nicks to stop Destroyers from mining on The Nethernet.</p>

<a href=\"/guide/tools/watchdogs\"><img class=\"thumb\" src=\"/images/shared/tools/small/watchdogs.jpg\" height=\"50\" alt=\"Watchdogs\" width=\"50\" /></a>

<h4><a href=\"/guide/tools/watchdogs\">Watchdogs</a></h4>

<p>At Level 5, Vigilante unlock the Watchdog tool. Watchdogs guard URLs and prevent players from leaving mines at those locations.</p>

<a href=\"/guide/lore/asynchronousrevenge/\"><img class=\"thumb\" src=\"/images/shared/tools/small/st_nicks.jpg\" height=\"50\" alt=\"Professor Thaddeus Esper\" width=\"50\" /></a>

<h4><a href=\"/guide/lore/asynchronousrevenge/\">\"Asychronous Revenge

with St. Nicks\"</a></h4>

<p>by Nameless Hoardes of the Dissatified</p>

</div>

<div class=\"width20\"></div>

<div class=\"width275\">

<a href=\"/guide/characters/victoria_ash\"><img class=\"thumb\" src=\"/images/guide/characters/victoriaash-50.png\" height=\"50\" alt=\"Victoria Ash\" width=\"50\" /></a>

<h4><a href=\"/guide/characters/victoria_ash\">Victoria Ash</a></h4>

<p>Victoria is the masked Vigilante of the Nethernet. Known for her illusiveness, many players are intriged as to what drives the motivations this young girl.<a href=\"/guide/characters/victoria_ash\">Learn More</a></p>

<a href=\"/guide/lore/ashestoashes/\"><img class=\"thumb\" src=\"/images/guide/lore/ashestoashes-50.png\" height=\"50\" alt=\"Professor Thaddeus Esper\" width=\"50\" /></a>

<h4><a href=\"/guide/lore/ashestoashes/\">\"Ashes to Ashes\"</a></h4>

<p>by Seraphina Brennan</p>

</div>"]

    @vigilantes = PmogClass.find_by_name('Vigilantes')
    @vigilantes.update_attributes(vigilantes_data)

    # insert/update the Bedouins entry in :classes
    bedouins_data = Hash[#:name => "Bedouins",
      :short_description => "Bedouins try to keep The Nethernet safe for other players. Bedouins are part of the Faction of Order.",
      :long_description => "<div class=\"copyTop\">

<h2>Fighting to Keeping it Safe</h2><p>Bedouins try to keep The Nethernet safe for other players. Bedouins are part of the Faction of Order.</p></div>

<div class=\"width275\">

<a href=\"/guide/tools/armor\"><img class=\"thumb\" src=\"/images/shared/tools/small/armor.jpg\" height=\"50\" alt=\"Armor\" width=\"50\" /></a>

<h4><a href=\"/guide/tools/armor\">Armor</a></h4>

<p>Bedouin protect themselves with Armor and seek out Mines to detonate.</p>

<a href=\"/guide/abilities/dodge\"><img class=\"thumb\" src=\"/images/shared/tools/small/dodge.jpg\" height=\"50\" alt=\"Dodge\" width=\"50\" /></a>

<h4><a href=\"/guide/abilities/dodge\">Dodge Ability</a></h4>

<p>Bedouin unlock the ability to Dodge Mines at Level 3. Rather than taking any damage, the Bedouin have a 10 percent chance of evading the mine.</p>

</div>

<div class=\"width20\"></div>

<div class=\"width275\">

<a href=\"/guide/lore/thefrontlines/\"><img class=\"thumb\" src=\"/images/guide/lore/frontlines-50.png\" height=\"50\" alt=\"The Front Lines\" width=\"50\" /></a>

<h4><a href=\"/guide/lore/thefrontlines/\">\"The Front Lines\"</a></h4>

<p>by Seraphina Brennan</p>

</div>"]

    @bedouins = PmogClass.find_by_name('Bedouins')
    @bedouins.update_attributes(bedouins_data)

    # insert/update the Shoats entry in :classes
    shoats_data = Hash[#:name => "Shoats",
#      :name => 'Shoats',
      :short_description => "Shoats are n00bs. Until you've picked a Class or reach Level 5, whichever comes first, you'll be known as a Shoat.",
      :long_description => "Shoats are free to roam The Nethernet as they will, associating with Order and Chaos both. Shoats may recline on the green swaths of PMOG space, under the glittering moon, thinking only of the joy of undiscovered portals - never fearing retribution or the unordering of their precious tag stacks. No, those thoughts are reserved for the dark moments of each day, when the Other rises in force against you and you must sacrifice your sweet pink flesh to the fires of battle. O! sweet Shoat, it is the best of times and the worst of times."]


    @Shoats = PmogClass.find_by_name('Shoats')
    @Shoats.update_attributes(shoats_data)
  end

  def self.down
  end
end
