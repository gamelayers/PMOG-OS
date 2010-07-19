#!/usr/bin/env ruby

# TODO - calculate everything as a percentage of the number of users.
# i.e. 10% of users will create a mission, or bird bot, or npc.
# and each mission will have avg. 4 branches, etc.

raise "usage: generate.rb RAILS_ENV" unless ARGV.size==1

ENV['RAILS_ENV'] = ARGV[0]

require File.dirname(__FILE__) + '/../../config/environment.rb'
require File.dirname(__FILE__) + "/names.rb"
require File.dirname(__FILE__) + "/markov_text.rb"
require File.dirname(__FILE__) + "/assets.rb"
require File.dirname(__FILE__) + "/random_date.rb"

# Generate users, missions, branches, npcs and bird bots along with images and thumbnails

puts "\n"
puts "This script is DESTRUCTIVE."
puts "All USERS, MISSIONS, NPCS AND BIRD BOTS are about to be deleted!"
puts "Abort NOW or the script will resume in ten seconds"
puts "\n"

sleep(10)

if (host = `uname -n`.strip == "ey01-s00094")
  puts "Will not run on the production slice. Hope that's ok."
  exit
end

puts "Starting.. "

bot_images = Dir[ File.dirname(__FILE__) + "/assets/bots/*" ]
user_images = Dir[ File.dirname(__FILE__) + "/assets/users/*" ]

urls = %w{ www.google.com www.google.co.uk www.suttree.com/archives www.links.net www.artserf.com www.casualgamedev.com www.gamelayers.com www ecolocal.com/discuss/ www.musicknows.com www.treehugger.com www.football365.com www.yahoo.com www.digg.com del.icio.us www.flickr.com www.myspace.com www.facebook.com www.pmog.com www.bbc.co.uk www.slashdot.org www.eurogamer.net www.popbitch.com reader.google.com www.suttree.com/about www.ecolocal.com/about www.gamelayers.com/team www.bud.com }
feeds = %w{ www.suttree.com/feed www.musicknows.com/feed del.icio.us/rss/suttree del.icio.us/rss/tags/suttree api.flickr.com/services/feeds/photos_public.gne?id=91768428@N00&amp;amp;lang=en-us&amp;format=rss_200 www.twitter.com/statuses/user_timeline/18923.rss http://newsrss.bbc.co.uk/rss/newsonline_uk_edition/front_page/rss.xml http://www.techdirt.com/techdirt_rss.xml http://feeds.feedburner.com/TechCrunch http://joi.ito.com/index.xml http://feeds.arstechnica.com/arstechnica/BAaf http://feeds.feedburner.com/Wonderland }

User.destroy_all
Npc.destroy_all
BirdBot.destroy_all
Mission.destroy_all

FileUtils.rm_rf( Dir[RAILS_ROOT + '/public/system/image_assets/*'] )
ActiveRecord::Base.connection.execute 'delete from assets'

# Users
count = 0
1000.times do
  count += 1
  count % 2 == 0 ? login = Names.boy + "_#{count}" : login = Names.girl + "_#{count}"
  count % 2 == 0 ? gender = "m" : gender = "f"
  count % 2 == 0 ? country = "United Kingdom" : country = "United States"
  count % 2 == 0 ? forename = Names.boy : forename = Names.girl

  u = User.create(
    :login => login,
    :email => "test_#{count}@example.com",
    :password => 'password',
    :password_confirmation => 'password',
    :time_zone => "Etc/UTC",
    :forename => forename,
    :surname => Names.surnames,
    :country => country,
    :gender => gender,
    :date_of_birth => RandomDate.random_date( :year => (rand(50) + 1950) )
  )
  
  filename = `pwd`.chomp + '/' + user_images[rand(user_images.size)].chomp
  AssetUpload.upload_image "./assets/users", u, "User", filename
  
  puts "User created - " + u.login
end

# Hack to create me :D
u = User.create(
  :login => 'suttree',
  :email => "duncan@suttree.com",
  :password => 'password',
  :password_confirmation => 'password',
  :gender => "m",
  :country => "United Kingdom",
  :forename => "Duncan",
  :surname => "Gough",
  :date_of_birth => "1975-02-23",
  :time_zone => "Etc/UTC"
)

filename = `pwd`.chomp + '/' + user_images[rand(user_images.size)].chomp
AssetUpload.upload_image "./assets/users", u, "User", filename

puts "User created - " + u.login
puts "Users created, now creating NPCs"

# NPCs
count = 0
100.times do
  count += 1
  count % 2 == 0 ? name = Names.boy + "Bot_#{count}" : name = Names.girl + "Bot_#{count}"

  n = Npc.create(
    :name => name,
    :description => "An example NPC bot (#{count})",
    :first_words => MarkovText.sample,
    :user_id => User.find( :first, :order => "rand()", :limit => 1 ).id
  )

  # locations, feeds, users
  10.times do
    if rand(2.size) % 2 == 0
      url = Url.normalise(urls[rand(urls.size)])
      if @location = Location.find_by_url(url)
        n.locations << @location unless n.locations.include? @location
      else
        n.locations.create(:url => url)
      end
    end
  end
  
  5.times do
    if rand(2.size) % 2 == 0
      url = Url.normalise(feeds[rand(feeds.size)])
      if @feed = Feed.find_by_url(url)
        n.feeds << @feed unless n.feeds.include? @feed
      else
        n.feeds.create(:url => url)
      end
    end
  end

  100.times do
    if rand(2.size) % 2 == 0
      n.users << User.find( :first, :order => "rand()", :limit => 1 )
    end
  end
  
  # image and thumbnails
  filename = `pwd`.chomp + '/' + bot_images[rand(bot_images.size)].chomp
  AssetUpload.upload_image "./assets/bots", n, "Npc", filename
  
  puts "NPC created - " + n.name
end

puts "NPCs created, now creating Bird Bots"

# Bird Bots
count = 0
200.times do
  count += 1
  count % 2 == 0 ? name = Names.boy + "Bot_#{count}" : name = Names.girl + "Bot_#{count}"

  b = BirdBot.create(
    :name => name,
    :description => "An example BirdBot bot (#{count})",
    :first_words => MarkovText.sample,
    :user_id => User.find( :first, :order => "rand()", :limit => 1 ).id
  )

  # locations, feeds, users
  10.times do
    if rand(2.size) % 2 == 0
      url = Url.normalise(urls[rand(urls.size)])
      if @location = Location.find_by_url(url)
        b.locations << @location unless b.locations.include? @location
      else
        @location = b.locations.create(:url => url)
      end
    end
  end
  
  url = Url.normalise(feeds[rand(feeds.size)])
  if @feed = Feed.find_by_url(url)
    b.feed = @feed
  else
    b.feed.create(:url => url)
  end
  b.save

  100.times do
    if rand(2.size) % 2 == 0
      b.users << User.find( :first, :order => "rand()", :limit => 1 )
    end
  end
  
  # image and thumbnails
  filename = `pwd`.chomp + '/' + bot_images[rand(bot_images.size)].chomp
  AssetUpload.upload_image "./assets/bots", b, "BirdBot", filename
  
  puts "BirdBot created - " + b.name
end

# Missions
count = 0
200.times do
  count += 1

  u = User.find( :first, :order => "rand()", :limit => 1 )
  m = u.missions.create(
    :name => "Test Mission #{count}",
    :description => MarkovText.sample
  )

  puts m.errors.full_messages.to_sentence
  puts "Mission created - " + m.name
end

puts "Missions created, now creating Branches"

# Branches
count = 0
1000.times do
  count += 1

  m = Mission.find( :first, :order => "rand()", :limit => 1 )

  parent_id = nil
  if rand(2.size) % 2 == 0
    parent = Branch.find( :first, :conditions => [ "mission_id = ?", m.id ], :order => "rand()", :limit => 1 )
    parent_id = parent.id unless parent.nil?
  end
  
  b = Branch.create(
    :description => MarkovText.sample,
    :mission_id => m.id,
    :parent_id => parent_id
  )
  
  if rand(20.size) % 2 == 0
    b.url = Url.normalise(urls[rand(urls.size)])
  elsif rand(20.size) % 4 == 0
    bb = BirdBot.find( :first, :order => "rand()", :limit => 1 )
    b.bird_bots << bb unless b.bird_bots.include? bb
  elsif rand(20.size) % 6 == 0
    npc = Npc.find( :first, :order => "rand()", :limit => 1 )
    b.npcs << npc unless b.npcs.include? npc
  elsif rand(20.size) % 8 == 0
    m = Mission.find( :first, :order => "rand()", :limit => 1 )
    b.missions << m unless b.missions.include? m
  elsif rand(20.size) % 10 == 0
    # Do nothing
  end
end

print "Done\n"