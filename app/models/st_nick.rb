# == Schema Information
# Schema version: 20081220201004
#
# Table name: st_nicks
#
#  id          :string(36)    primary key
#  user_id     :string(36)    
#  attachee_id :string(36)    
#  created_at  :datetime      
#  updated_at  :datetime      
#

class StNick < ActiveRecord::Base
  belongs_to :user # the victim
  belongs_to :attachee, :class_name => 'User' # the perpetrator

  class StNickError < PMOG::PMOGError; end

  class MaximumStNicksError < StNickError
    def default
      "That user is already covered in enough St. Nicks, thank you."
    end
  end

  class OutOfStNicksError < User::InventoryError
    def default
      "You are out of St. Nicks.  Purchase more at the Shoppe."
    end
  end

  class JerduGainsError < StNickError
    def default
      "Not so fast!  Jerdu Gains has put an end to these shenanigans."
    end
  end

  def before_create
    self.id = create_uuid
  end

  class << self
    def create_and_attach(current_user, params)
      @st_nick = nil
      target_user = User.find( :first, :conditions => { :login => params[:user_id] } )
      raise User::PlayerNotFound unless target_user
      raise OutOfStNicksError unless current_user.inventory.st_nicks > 0

      if(params[:upgrade] && params[:upgrade][:ballistic] && params[:upgrade][:ballistic].to_bool)
        # raise JerduGainsError

        # ballistic nicks have their effects calculated immediately
        ballistic_nick_settings = Upgrade.cached_single('ballistic_nick')

        raise User::InsufficientPingsError.new("You do not have enough pings to make a ballistic St. Nick") if current_user.available_pings < ballistic_nick_settings.ping_cost
        raise User::InsufficientExperienceError.new("You are not a high enough level Vigilante to use ballistic St. Nicks") if current_user.levels[:vigilante] < ballistic_nick_settings.level
        BallisticNick.transaction do
          if BallisticNick.execute("SELECT COUNT(*) FROM ballistic_nicks WHERE victim_id = '#{target_user.id}' FOR UPDATE").fetch_row[0].to_i >= GameSetting.value('Max Ballistic Nicks per Player').to_i
            raise MaximumStNicksError.new(target_user.login + ' is already covered in Ballistic Nicks!')
          else
            # put the nick on the player
            target_user.ballistic_nicks.create(:perp_id => current_user.id)

            current_user.deduct_pings ballistic_nick_settings.ping_cost
            current_user.inventory.withdraw :st_nicks
            current_user.upgrade_uses.reward :ballistic_nick

            "Ballistic St. Nick released!"
          end
        end
      else
        # regular nicks get put in the database 
        StNick.transaction do
        # Rails way, disabled because it doesn't actually lock anything
          # get a lock on all nicks on this user.  simultaneous transactions that reach this point will block here.
          # existing_nicks = StNick.find(:all, :conditions => "user_id = '#{@user.id}'", :lock => true)

        # MYSQL way (temporary, seeing if it even works)
          # attempted hack to make COUNT() valid, we should have a lock on all related records maybe
          if StNick.execute("SELECT COUNT(*) FROM st_nicks WHERE user_id = '#{target_user.id}' FOR UPDATE").fetch_row[0].to_i >= GameSetting.value('Max St Nicks per Player').to_i
            raise MaximumStNicksError.new(target_user.login + ' is already covered in St Nicks!')
          else
            # St Nick attachment succeeded - award classpoints
            current_user.inventory.withdraw :st_nicks
            current_user.tool_uses.reward :st_nicks
            # finally, attach the nick
            @st_nick = target_user.st_nicks.create(:attachee => current_user)

            "St Nick Attached!"
          end
        end
      end

    end
  end
end
