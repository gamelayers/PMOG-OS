class NpcActionManager

  def tick
    # the bot's behavior is seeded off of this random var
    @rand = rand 100

    # act as the bot at the front of the queue
    send "act_as_#{@@queue[0]}"
    # rotate the front player to the end of the queue
    @@queue.push @@queue.shift
  end

  protected
  @@queue = ['jerdu_gains','thomas_hoggins','victoria_ash','bloody_tuesday']

  @@bedouin = PmogClass.find_by_name("Bedouins")
  @@destroyer = PmogClass.find_by_name("Destroyers")
  @@benefactor = PmogClass.find_by_name("Benefactors")
  @@vigilante = PmogClass.find_by_name("Vigilantes")

  @@jerdu = User.find_by_login('jerdu_gains')
  @@hoggins = User.find_by_login('thomas_hoggins')
  @@tuesday = User.find_by_login('bloody_tuesday')
  @@victoria = User.find_by_login('victoria_ash')

  def act_as_jerdu_gains
    # jerdu has a lame turn that i suspect will frequently no-event, so he goes twice
    2.times do
      mine = random_location.mines.first
      # pop a mine, otherwise, go home
      mine.nil? ? break : mine.deplete

      Event.record(:user_id => current_user.id,
        :recipient_id => mine.user.id,
        :context => 'mine_deflected',
        :message => "foiled <a href=\"#{@@jerdu.pmog_host}/users/#{mine.user.login}\">#{mine.user.login}'s</a> mine with armor.")
    end
  end

  def act_as_thomas_hoggins
    # this event has hoggins place a random giftcard on a website
    if @rand < 30
      location = random_location

      location.giftcards.create :user => @@hoggins

      Event.record(:user_id => @@hoggins.id,
        :context => 'giftcard_stashed',
        :message => "left a #{Ability.cached_single(:giftcard).name.singularize} somewhere on <a href=\"http://#{Url.host(location.url)}\">#{Url.host(location.url)}</a>")
    # this event has him deposit a slightly larger pile of loot somewhere
    elsif @rand < 40
      location = random_location

      crate = Crate.create :user_id => @@hoggins.id, :location => location, :comments => "Enjoy!"
      Inventory.create :owner_id => crate.id, :owner_type => 'Crate', :datapoints => 100

      Event.record(:user_id => @@hoggins.id,
        :context => 'crate_stashed',
        :message => "stashed a crate somewhere on <a href=\"http://#{Url.host(location.url)}\">#{Url.host(location.url)}</a>")
    # this event gives 5 armor to a random bedouin leader
    elsif @rand < 70
      target = DailyClasspoints.random_leader @@bedouin.id
      location = Location.caches(:find_or_create_by_url, :with => "http://thenethernet.com/users/#{target.login}")

      crate = Crate.create :user_id => @@hoggins.id, :location => location, :comments => "Enjoy!"
      Inventory.create :owner_id => crate.id, :owner_type => 'Crate', :armor => 5

      Event.record(:user_id => @@hoggins.id,
        :context => 'crate_stashed',
        :message => "stashed a crate somewhere on <a href=\"http://thenethernet.com\">thenethernet.com</a>")
    # this event gives 100 dp to a random benefactor leader
    else
      target = DailyClasspoints.random_leader @@benefactor.id
      location = Location.caches(:find_or_create_by_url, :with => "http://thenethernet.com/users/#{target.login}")

      crate = Crate.create :user_id => @@hoggins.id, :location => location, :comments => "Enjoy!"
      Inventory.create :owner_id => crate.id, :owner_type => 'Crate', :datapoints => 100

      Event.record(:user_id => @@hoggins.id,
        :context => 'crate_stashed',
        :message => "stashed a crate somewhere on <a href=\"http://thenethernet.com\">thenethernet.com</a>")
    end
  end

  def act_as_bloody_tuesday
    # this action mines a random site
    if @rand < 40
      location = random_location

      @@tuesday.mines.create :location_id => location.id, :charges => 1, :abundant => false

      Event.record(:user_id => @@tuesday.id,
        :context => 'mine_deployed',
        :message => "deployed a mine on <a href=\"http://#{Url.host(location.url)}\">#{Url.host(location.url)}</a>")
    # this action throws a grenade at one of the other npcs
    elsif @rand < 70
      victim = [@@jerdu, @@hoggins, @@victoria].rand
      victim.grenades.create :perp => @@tuesday unless Grenade.execute("SELECT COUNT(*) FROM grenades WHERE victim_id = '#{victim.id}' FOR UPDATE").fetch_row[0].to_i >= GameSetting.value('Max Grenades per Player').to_i
    # this action throws a grenade at a player from an offending leaderboard
    else
      victim = DailyClasspoints.random_leader [@@bedouin.id, @@vigilante.id].rand
      victim.grenades.create :perp => @@tuesday unless Grenade.execute("SELECT COUNT(*) FROM grenades WHERE victim_id = '#{victim.id}' FOR UPDATE").fetch_row[0].to_i >= GameSetting.value('Max Grenades per Player').to_i
    end
  end

  def act_as_victoria_ash
    # this action deploys a watchdog on a random site
    if @rand < 40
      location = random_location

      location.watchdogs.create :user => @@victoria

      Event.record(:user_id => @@victoria.id,
        :context => 'watchdog_deployed',
        :message => "unleashed a watchdog on <a href=\"http://#{Url.host(location.url)}\">#{Url.host(location.url)}</a>")
    # this action st nicks bloody tuesday
    elsif @rand < 70
      @@tuesday.st_nicks.create :attachee => @@victoria unless StNick.execute("SELECT COUNT(*) FROM st_nicks WHERE user_id = '#{@@tuesday.id}' FOR UPDATE").fetch_row[0].to_i >= GameSetting.value('Max St Nicks per Player').to_i
    # this action st nicks a random top destroyer
    else
      victim = DailyClasspoints.random_leader @@destroyer.id
      victim.st_nicks.create :attachee => @@victoria unless StNick.execute("SELECT COUNT(*) FROM st_nicks WHERE user_id = '#{@@tuesday.id}' FOR UPDATE").fetch_row[0].to_i >= GameSetting.value('Max St Nicks per Player').to_i
    end
  end

  @@WHITE_LOCATIONS = [
    "http://www.google.com",
    "http://www.yahoo.com",
    "http://www.facebook.com",
    "http://www.twitter.com",
    "http://www.youtube.com",
    "http://www.flickr.com",
    "http://www.xkcd.com",
    "http://www.reddit.com",
    "http://www.digg.com",
    "http://www.wikipedia.org",
    "http://www.boingboing.net",
    "http://icanhascheezburger.com/"]

  def random_location
    Location.find_or_create_by_url @@WHITE_LOCATIONS.rand
  end

end
