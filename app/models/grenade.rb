class Grenade < ActiveRecord::Base
  belongs_to :perp, :class_name => 'User'
  belongs_to :victim, :class_name => 'User'

  acts_as_cached

  validates_presence_of :perp_id, :victim_id

  # Restricted attributes and included association for JSON output
  cattr_accessor :private_api_fields, :included_api_associations
  @@private_api_fields = []
  @@included_api_associations = [ :user ]

  class GrenadeError < PMOG::PMOGError; end
  
  class OutOfGrenades < GrenadeError
    def default
      "You don't have any grenades!  Head to the Shoppe to stock up."
    end
  end

  class StNicked < GrenadeError
    def default 
      "You were St Nicked."
    end
  end
  
  class TooManyGrenades < GrenadeError
    def default
      "That's enough Grenades, thank you!"
    end
  end

  def before_create
    self.id = create_uuid
  end

  def deplete(amount = 1)
    self.charges -= amount
    self.charges <= 0 ? self.destroy : self.save
  end
  
  class << self
    def create_and_attach(current_user, params)
      raise OutOfGrenades unless current_user.inventory.grenades >= 1
      
      target_player = nil
      begin
        target_player = User.find_by_login(params[:user_id])
      rescue ActiveRecord::RecordNotFound
        raise User::PlayerNotFound
      end

      raise TooManyGrenades if Grenade.execute("SELECT COUNT(*) FROM grenades WHERE victim_id = '#{target_player.id}' FOR UPDATE").fetch_row[0].to_i >= GameSetting.value('Max Grenades per Player').to_i

      ### VALIDATION COMPLETE ###

      @deploy_message = "Grenade thrown!"

      current_user.inventory.withdraw :grenades

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

          @deploy_message = "Grenade Thrown!  You disarmed #{@st_nick.attachee.login}'s St Nick!"

        ### DODGE ###
        elsif current_user.dodge_roll?
          dodge_settings = Ability.cached_single(:dodge)
          current_user.ability_uses.reward :dodge
          current_user.deduct_pings dodge_settings.ping_cost

          Event.record :context => 'st_nick_dodged',
            :user_id => current_user.id,
            :recipient_id => @st_nick.attachee.id,
            :message => "nimbly Dodged <a href=\"#{@st_nick.pmog_host}}/users/#{@st_nick.attachee.login}\">#{@st_nick.attachee.login}'s</a> St Nick!"

          @deploy_message = "Grenade Thrown!  You dodged #{@st_nick.attachee.login}'s St Nick!"

        ### ST NICK SUCCESS ###
        else
          unless current_user.st_nicks.empty?
            @deploy_message = "#{@st_nick.attachee.login} foiled your attempt to throw a Grenade with a St Nick.  You still have #{current_user.st_nicks.size} attached."
          else
            @deploy_message = "#{@st_nick.attachee.login} foiled your attempt to throw a Grenade with a St Nick.  But now all St Nicks are cleared."
          end

          @st_nick.attachee.reward_pings Ping.value("Damage Rival") if @st_nick.attachee.buddies.rivaled_with? current_user

          Event.record :context => 'st_nick_activated',
            :user_id => current_user.id,
            :recipient_id => @st_nick.attachee.id,
            :message => "had their Grenade foiled by <a href=\"#{@st_nick.pmog_host}/users/#{@st_nick.attachee.login}\">#{@st_nick.attachee.login}'s</a> St Nick"

          raise StNicked.new(@deploy_message)
        end
      end

      ### GRENADE SUCCESS ###
      target_player.grenades.create :perp => current_user

      current_user.tool_uses.reward :grenades

      @deploy_message
    end  
  end
end
