class StatusEffect < ActiveRecord::Base
  include AvatarHelper

  belongs_to :user
  belongs_to :ability

  class StatusEffectError < PMOG::PMOGError; end

  class NoPlayersInvited < StatusEffectError
    def default
      "You haven't invited enough friends to use this tool!"
    end
  end

  class NoCastsLeft < StatusEffectError
    def default
      "You can't use this ability any more times today!"
    end
  end

  class TooManyCharges_Impede < StatusEffectError
    def default
      "Impede Failed!  This player is close to the limit of #{GameSetting.value('Max Impedes Per Player').to_i} charges."
    end
  end

  class TooManyCharges_Overclock < StatusEffectError
    def default
      "Overclock Failed!  This player is close to the limit of #{GameSetting.value('Max Overclocks Per Player').to_i} charges."
    end
  end

  class NoSelfBuffs < StatusEffectError
    def default
      "Sorry, you can't use that ability on yourself"
    end
  end

  class WrongFaction < StatusEffectError
    def default
      "You aren't the right faction to use this ability!"
    end
  end

  def self.use_and_decrement_with_lock user_id, ability_id, &block
    transaction do
      buff_status = find(:first, :conditions => {:user_id => user_id, :ability_id => ability_id}, :lock => true)

      if !buff_status.nil? and buff_status.charges > 0
        buff_status.charges -= 1
        buff_status.save!

        yield

      end # else, the buff has already expired, so we don't perform its behavior
    end
  end

  def self.impede current_user, target_login
    raise NoSelfBuffs if current_user.login == target_login

    target_user = User.find( :first, :conditions => { :login => target_login } )
    raise User::PlayerNotFound unless target_user

    raise WrongFaction unless current_user.user_level.order_or_chaos? == 'chaos'

    raise NoPlayersInvited unless current_user.badges.find(:first, :conditions => {:name => 'Inviting'})

    buff_settings = Ability.cached_single('impede')

    transaction do
      buff = StatusEffect.find(:first, :conditions => {:user_id => target_user.id, :ability_id => buff_settings.id}, :lock => true)

      raise TooManyCharges_Impede if !buff.nil? and buff.charges > GameSetting.value('Max Impedes Per Player').to_i - buff_settings.charges # if the buff stack is 20 or less, we can add

      user_ability_status = AbilityStatus.find(:first, :conditions => {:user_id => current_user.id}, :lock => true)

      raise NoCastsLeft if user_ability_status.daily_invite_buffs.nil? || user_ability_status.daily_invite_buffs <= 0

      ### VALIDATION COMPLETE ###

      user_ability_status.daily_invite_buffs -= 1
      user_ability_status.save!

      if buff.nil?
        buff = create(:user_id => target_user.id, :source_id => current_user.id, :charges => buff_settings.charges, :ability_id => buff_settings.id)
      else
        buff.charges += buff_settings.charges
        buff.source_id = current_user.id
        buff.shown = false
        buff.save!
      end
    end

    current_user.reward_pings Ping.value('Damage Rival') # this is a buff, you get pings regardless of who you cast it on
    current_user.ability_uses.reward :impede

    Event.record :context => "impede_cast",
      :user_id => current_user.id,
      :recipient_id => target_user.id,
      :message => "impeded <a href=\"#{target_user.pmog_host}/users/#{target_user.login}\">#{target_user.login}'s</a> leveling progress!"

    return "#{target_login} Impeded!"
  end

  def self.overclock current_user, target_login
    raise NoSelfBuffs if current_user.login == target_login

    target_user = User.find( :first, :conditions => { :login => target_login } )
    raise User::PlayerNotFound unless target_user

    raise WrongFaction unless current_user.user_level.order_or_chaos? == 'order'

    raise NoPlayersInvited unless current_user.badges.find(:first, :conditions => {:name => 'Inviting'})

    buff_settings = Ability.cached_single('overclock')

    transaction do
      buff = StatusEffect.find(:first, :conditions => {:user_id => target_user.id, :ability_id => buff_settings.id}, :lock => true)

      raise TooManyCharges_Overclock if !buff.nil? and buff.charges > GameSetting.value('Max Overclocks Per Player').to_i - buff_settings.charges

      user_ability_status = AbilityStatus.find(:first, :conditions => {:user_id => current_user.id}, :lock => true)

      raise NoCastsLeft if user_ability_status.daily_invite_buffs.nil? || user_ability_status.daily_invite_buffs <= 0

      ### VALIDATION COMPLETE ###

      user_ability_status.daily_invite_buffs -= 1
      user_ability_status.save!

      if buff.nil?
        buff = create(:user_id => target_user.id, :source_id => current_user.id, :charges => buff_settings.charges, :ability_id => buff_settings.id)
      else
        buff.charges += buff_settings.charges
        buff.source_id = current_user.id
        buff.shown = false
        buff.save!
      end
    end

    current_user.reward_pings Ping.value('Aid Ally') # this is a buff, you get pings regardless of who you cast it on
    current_user.ability_uses.reward :overclock

    Event.record :context => "overclock_cast",
      :user_id => current_user.id,
      :recipient_id => target_user.id,
      :message => "overclocked <a href=\"#{target_user.pmog_host}/users/#{target_user.login}\">#{target_user.login}'s</a> leveling progress!"

    return "#{target_login} Overclocked!"
  end

  def before_create
    self.id = create_uuid
  end

  def to_json_overlay(extra_args = {})
    source_player = User.find(self.source_id)
    Hash[
      :id => self.id,
      :user => source_player.login,
      :avatar => avatar_path_for_user(:user => source_player, :size => 'mini'),
      :charges => self.charges,
    ].merge(extra_args).to_json
  end

  def show!
    self.update_attribute(:shown, true)
  end

  def unshow!
    self.update_attribute(:shown, false)
  end
end
