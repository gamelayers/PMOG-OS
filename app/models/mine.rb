# == Schema Information
# Schema version: 20081220201004
#
# Table name: mines
#
#  id          :string(36)    primary key
#  user_id     :string(36)
#  location_id :string(36)
#  created_at  :datetime
#  updated_at  :datetime
#  charges     :integer(11)   default(0)
#

class Mine < ActiveRecord::Base
  belongs_to :location
  #belongs_to :old_location
  belongs_to :user

  acts_as_cached

  validates_presence_of :location_id, :user_id

  # Restricted attributes and included association for JSON output
  cattr_accessor :private_api_fields, :included_api_associations
  @@private_api_fields = []
  @@included_api_associations = [ :user ]

  class MineError < PMOG::PMOGError; end

  class OutOfMinesError < MineError
    def default
      "You need to purchase more mines"
    end
  end

  class StNickedError < MineError
    def default
      "You were St. Nicked."
    end
  end

  class WatchdoggedError < MineError
    def default
      "You were chased away by a Watchdog."
    end
  end

  class TooManyMinesError < MineError
    def default
      "That's enough mines, thank you!"
    end
  end

  def before_create
    self.id = create_uuid
  end

  def deplete(amount=1)
    self.charges -= amount
    self.charges <= 0 ? self.destroy : self.save
  end

  class << self
    def create_and_deposit(current_user, params)
      @deployed_mine = nil
      @deploy_message = "Mine Laid!  How uncouth!"

      begin
        @location = Location.find(params[:location_id])
      # hackish translation to a user-facing error
      rescue ActiveRecord::RecordNotFound
        raise Location::LocationNotFound
      end

      mine_data = {:location_id => @location.id,
        :charges => 1,
        :stealth => false,
        :abundant => false}

      # make sure the player is even allowed to lay a mine here
      raise OutOfMinesError.new("You don't have any Mines! Head to the Shoppe to stock up.") unless current_user.inventory.mines > 0
      raise Location::ProtectedByPmog if @location.protected_by_pmog?

      # also verify upgrade eligibility
      total_ping_cost = 0

      if(params[:stealth].to_bool)
        stealth_settings = Upgrade.cached_single('stealth_mine')
        raise User::InsufficientExperienceError.new("You must be a Level #{stealth_settings.level} Destroyer in order to lay a Stealth Mine") if current_user.levels[:destroyer] < stealth_settings.level
        raise User::InsufficientPingsError.new("You don't have enough pings to create a Stealth Mine!") if current_user.available_pings < stealth_settings.ping_cost
        total_ping_cost += stealth_settings.ping_cost
        mine_data[:stealth] = true
        @deploy_message = "Stealth " + @deploy_message
      end

      if(params[:abundant].to_bool)
        abundant_mine_settings = Upgrade.cached_single('abundant_mine')
        raise User::InsufficientExperienceError.new("You must be a Level #{abundant_mine_settings.level} Destroyer in order to lay an Abundant Mine.") if current_user.levels[:destroyer] < abundant_mine_settings.level
        raise User::InsufficientPingsError.new("You don't have enough pings to create an Abundant Mine.") if current_user.available_pings < abundant_mine_settings.ping_cost
        total_ping_cost += abundant_mine_settings.ping_cost
        mine_data[:abundant] = true
        @deploy_message = "Abundant " + @deploy_message
      end

      raise User::InsufficientPingsError.new("You do not have enough pings for these upgrades") if current_user.available_pings < total_ping_cost

      ### VALIDATION COMPLETE ###

      # remove the mine from the inventory now that we know we aren't erroring out
      current_user.inventory.withdraw :mines

      ### ST NICKS ###
      if current_user.st_nicks.any?
        @st_nick = current_user.st_nicks.first.destroy

        ### DISARM ###
        if current_user.disarm_roll?
          disarm_settings = Ability.cached_single(:disarm)

          current_user.ability_uses.reward :disarm
          current_user.inventory.deposit :st_nicks
          current_user.deduct_pings disarm_settings.ping_cost

          Event.record :context => 'st_nick_disarmed',
            :user_id => current_user.id,
            :recipient_id => @st_nick.attachee.id,
            :message => "artfully Disarmed <a href=\"#{@st_nick.pmog_host}}/users/#{@st_nick.attachee.login}\">#{@st_nick.attachee.login}'s</a> St Nick!"

          @deploy_message = "Mine Laid!  You disarmed #{@st_nick.attachee.login}'s St Nick!"

        ### DODGE ###
        elsif current_user.dodge_roll?
          dodge_settings = Ability.cached_single(:dodge)

          current_user.ability_uses.reward :dodge
          current_user.deduct_pings dodge_settings.ping_cost

          Event.record :context => 'st_nick_dodged',
            :user_id => current_user.id,
            :recipient_id => @st_nick.attachee.id,
            :message => "nimbly Dodged <a href=\"#{@st_nick.pmog_host}}/users/#{@st_nick.attachee.login}\">#{@st_nick.attachee.login}'s</a> St Nick!"

          @deploy_message = "Mine Laid!  You dodged #{@st_nick.attachee.login}'s St Nick!"

        ### ST NICK SUCCESS ###
        else
          unless current_user.st_nicks.empty?
            @deploy_message = "#{@st_nick.attachee.login} foiled your attempt to deploy a Mine here by using a St Nick.  You still have #{current_user.st_nicks.size} attached."
          else
            @deploy_message = "#{@st_nick.attachee.login} foiled your attempt to deploy a Mine here by using a St Nick.  But now all St Nicks are cleared."
          end

          @st_nick.attachee.reward_pings Ping.value("Damage Rival") if @st_nick.attachee.buddies.rivaled_with? current_user

          Event.record :context => 'st_nick_activated',
            :user_id => current_user.id,
            :recipient_id => @st_nick.attachee.id,
            :message => "had their Mine foiled by <a href=\"#{@st_nick.pmog_host}/users/#{@st_nick.attachee.login}\">#{@st_nick.attachee.login}'s</a> St Nick"

          raise StNickedError.new(@deploy_message)
        end
      end

      ### WATCHDOGS ###
      if @location.watchdogs.any?
        watchdog = @location.watchdogs.first.destroy

        Event.record :context => 'watchdog_activated',
          :user_id => current_user.id,
          :recipient_id => watchdog.user.id,
          :message => "was hounded away from <a href=\"http://#{Url.host(@location.url)}\">#{Url.host(@location.url)}</a> by <a href=\"#{watchdog.pmog_host}/users/#{watchdog.user.login}\">#{watchdog.user.login}</a>",
          :details => "You left this watchdog at <a href=\"#{watchdog.location.url}\">#{watchdog.location.url}</a> on #{watchdog.created_at.to_s}."

        unless @location.watchdogs.empty?
          @deploy_message = "#{watchdog.user.login}'s watchdog chased you away. You can spot #{@location.watchdogs.size} more growling in the distance."
        else
          @deploy_message = "#{watchdog.user.login}'s Watchdog chased you away.  The site looks safe now, though."
        end

        watchdog.user.reward_pings Ping.value("Damage Rival") if watchdog.user.buddies.rivaled_with? current_user

        raise WatchdoggedError.new(@deploy_message)
      end

      @deployed_mine = current_user.mines.create mine_data
      current_user.deduct_pings total_ping_cost

      # give tool uses for ALL upgrades used
      if mine_data[:abundant]
        current_user.upgrade_uses.reward :abundant_mine
      end

      if mine_data[:stealth]
        current_user.upgrade_uses.reward :stealth_mine
      end

      # only give a normal tool use if the mine has no upgrades
      unless mine_data[:abundant] || mine_data[:stealth]
        current_user.tool_uses.reward :mines
      end

      # only render the event if its not a stealth crate
      unless mine_data[:stealth]
        Event.record(:user_id => current_user.id,
          :context => 'mine_deployed',
          :message => "deployed a Mine on <a href=\"http://#{Url.host(@location.url)}\">#{Url.host(@location.url)}</a>")
      end

      [@deployed_mine, @deploy_message]
    end

    # This can be expanded upon, if required, but for now let's just pull
    # out an active mine without hurting the database too much - duncan 05/11/08
    def find_first_random_and_appropriate_for(current_user)
      mines = find(:all, :order => 'created_at DESC', :limit => 100)
      mines.reject{ |m|
        m.location.nil? ||
        m.location.is_pmog_url  ||
        current_user.daily_domains.recently_visited?(m.location)
      }.rand
    end

    def triggered_this_week
      get_cache('triggered_this_week') do
        raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
        connection = self.connection
        establish_connection configurations['slave']
        tool_id = Tool.cached_single('armor')
        data = ToolUse.find(:all, :select => 'COUNT(user_id) AS count, DATE(created_at) AS date', :conditions => ['tool_id = ? AND created_at BETWEEN ? AND ?', tool_id, 0.weeks.ago.at_beginning_of_week.to_time, 0.weeks.ago.at_end_of_week.to_time], :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        self.connection = connection
        data
      end
    end

    def triggered_last_week
      get_cache('triggered_last_week') do
        raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
        connection = self.connection
        establish_connection configurations['slave']
        tool_id = Tool.cached_single('armor')
        data = ToolUse.find(:all, :select => 'COUNT(user_id) AS count, DATE(created_at) AS date', :conditions => ['tool_id = ? AND created_at BETWEEN ? AND ?', tool_id, 1.week.ago.at_beginning_of_week.to_time, 1.week.ago.at_end_of_week.to_time], :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        self.connection = connection
        data
      end
    end
  end
end
