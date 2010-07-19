# == Schema Information
# Schema version: 20081220201004
#
# Table name: watchdogs
#
#  id          :string(36)    primary key
#  location_id :string(36)    
#  user_id     :string(36)    
#  created_at  :datetime      
#  updated_at  :datetime      
#

class Watchdog < ActiveRecord::Base
  belongs_to :location
  #belongs_to :old_location
  belongs_to :user

  class WatchdogError < PMOG::PMOGError; end
  
  class ProtectedByPmog < WatchdogError
    def default
      "No dogs allowed on thenethernet.com!"
    end
  end

  class MaximumWatchdogsFromUserError < WatchdogError
    def default
      'This location is already guarded by enough of your dogs.'
    end
  end

  class MaximumWatchdogsError < WatchdogError
    def default
      'This location is already guarded by a sufficiently vicious pack of dogs.'
    end
  end

  class OutOfWatchdogsError < WatchdogError
    def default
      'To the pound! You need to purchase more Watchdogs.'
    end
  end

  def before_create
    self.id = create_uuid
  end

  class << self
    #FIXME refactor this to create and deploy/deposit, copypastefail >:|
    def create_and_attach(current_user, params)
      begin
        @location = Location.find(params[:location_id])
      rescue ActiveRecord::RecordNotFound
        raise Location::LocationNotFound
      end

      raise User::InsufficientExperienceError.new("You must be a level #{Tool.cached_single(:watchdogs).level} Vigilante to use this tool.") if current_user.levels[:vigilante] < Tool.cached_single(:watchdogs).level

      raise MaximumWatchdogsFromUserError if Watchdog.execute("SELECT COUNT(*) FROM watchdogs WHERE location_id = '#{@location.id}' AND user_id = '#{current_user.id}' FOR UPDATE").fetch_row[0].to_i >= GameSetting.value('Max Watchdogs per URL').to_i

      raise ProtectedByPmog if @location.protected_by_pmog?

      raise OutOfWatchdogsError unless current_user.inventory.watchdogs > 0

      ### VALIDATION COMPLETE ###

      @watchdog = @location.watchdogs.create(:user => current_user)

      # Watchdog attachment succeeded - award classpoints
      current_user.inventory.withdraw :watchdogs
      current_user.tool_uses.reward :watchdogs

      Event.record :context => 'watchdog_deployed',
        :user_id => current_user.id,
        :message => "unleashed a watchdog somewhere on <a href=\"http://#{Url.host(@location.url)}\">#{Url.host(@location.url)}</a>"

      @watchdog
    end
  end
end
