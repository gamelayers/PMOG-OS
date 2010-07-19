#NOTE: bad coding practice abounds in this file, but ideally it is both bad (to read) and fast.

class UserLevel < ActiveRecord::Base
  acts_as_cached
  after_save :expire_cache

  belongs_to :user

  class UserLevelError < PMOG::PMOGError
  end

  class InvalidClassnameError < UserLevelError
    def default
      "Invalid class name specified."
    end
  end

  def before_create
    self.id = create_uuid
  end

  def unlocked? action
    case action
      when :giftcard, :mines, :st_nicks, :portals, :lightposts, :armor
        true
      when :skeleton_keys
        Tool.cached_single(:skeleton_keys).level <= seer
      when :dodge
        Ability.cached_single(:dodge).level <= bedouin
      when :disarm
        Ability.cached_single(:disarm).level <= bedouin
      when :vengeance
        Ability.cached_single(:vengeance).level <= bedouin
      when :crates
        Tool.cached_single(:crates).level <= benefactor
      when :stealth_crate
        Upgrade.cached_single(:stealth_crate).level <= benefactor
      when :puzzle_crate
        Upgrade.cached_single(:puzzle_crate).level <= benefactor
      when :ever_crate
        Upgrade.cached_single(:ever_crate).level <= benefactor
      when :exploding_crate
        Upgrade.cached_single(:exploding_crate).level <= destroyer
      when :stealth_mine
        Upgrade.cached_single(:stealth_mine).level <= destroyer
      when :grenades
        Tool.cached_single(:grenades).level <= destroyer
      when :watchdogs
        Tool.cached_single(:watchdogs).level <= vigilante
      when :give_dp
        Upgrade.cached_single(:give_dp).level <= seer
    end
  end

  def levelup_event_for(assoc)
    assoc = self.primary_class if(assoc == 'primary')
    assoc = highest_level_class if(assoc == 'shoat')

    Event.record :context => 'user_leveled',
      :user_id => self.user.id,
      :recipient_id => self.user.id,
      :message => "reached level #{send(assoc)} #{assoc.titleize}",
      :details => 'Learn more at <a href="http://thenethernet.com/guide/rules/levels">the Levels Page in The Nethernet Guide</a>'

    self.save
  end

  # NOTE: this is the only setter we should be using, this is called from [ability/misc_action/tool/upgrade]_uses_extension.rb:reward
  def reward_classpoints(game_event)
    # return immediately for the 0cp abilities that make it here
    return if game_event.classpoints == 0 or game_event.classpoints.nil?

    classpoints = game_event.classpoints

    ### IMPEDE AND OVERCLOCK ###
    buff_settings = Ability.cached_single('overclock')
    StatusEffect.use_and_decrement_with_lock self.user.id, buff_settings.id do
      classpoints += buff_settings.value
    end

    buff_settings = Ability.cached_single('impede')
    StatusEffect.use_and_decrement_with_lock self.user.id, buff_settings.id do
      classpoints -= buff_settings.value
    end

    ### CLASSPOINTS DISTRIBUTION ###
    case game_event.url_name
      when 'watchdogs', 'st_nicks', 'ballistic_nick'
        old_level = self.vigilante
        self.vigilante_cp.nil? ? self.vigilante_cp = 0 : self.vigilante_cp += classpoints
        levelup_event_for("vigilante") if old_level < self.vigilante
      when 'exploding_crate', 'mines', 'grenades', 'abundant_mine', 'stealth_mine'
        old_level = self.destroyer
        self.destroyer_cp.nil? ? self.destroyer_cp = 0 : self.destroyer_cp += classpoints
        levelup_event_for("destroyer") if old_level < self.destroyer
      when 'crates', 'puzzle_crate', 'giftcard', 'ever_crate', 'stealth_crate'
        old_level = self.benefactor
        self.benefactor_cp.nil? ? self.benefactor_cp = 0 : self.benefactor_cp += classpoints
        levelup_event_for("benefactor") if old_level < self.benefactor
      when 'portals', 'give_dp', 'portal_transportation', 'jaunt', 'create_skeleton_key', 'skeleton_keys'
        old_level = self.seer
        self.seer_cp.nil? ? self.seer_cp = 0 : self.seer_cp += classpoints
        levelup_event_for("seer") if old_level < self.seer
      when 'armor', 'dodge', 'disarm', 'vengeance'
        old_level = self.bedouin
        self.bedouin_cp.nil? ? self.bedouin_cp = 0 : self.bedouin_cp += classpoints
        levelup_event_for("bedouin") if old_level < self.bedouin
      when 'lightposts', 'mission_taken', 'puzzle_post', 'mission_published'
        old_level = self.pathmaker
        self.pathmaker_cp.nil? ? self.pathmaker_cp = 0 : self.pathmaker_cp += classpoints
        levelup_event_for("pathmaker") if old_level < self.pathmaker
      else
        raise Exception.new("Invalid ability keyname specified")
    end
    DailyClasspoints.update_total_by self.user.id, game_event.pmog_class_id, classpoints
    self.save
  end

  def bedouin_cp=(val)
    write_attribute(:bedouin_cp, val)
    expire_cache("bedouin")
  end

  def bedouin
    get_cache("bedouin", :ttl => 1.day) do
      Level.calculate_single(self.bedouin_cp, self.user.total_datapoints)
    end
  end

  def benefactor_cp=(val)
    write_attribute(:benefactor_cp, val)
    expire_cache("benefactor")
  end

  def benefactor
    get_cache("benefactor", :ttl => 1.day) do
      Level.calculate_single(self.benefactor_cp, self.user.total_datapoints)
    end
  end

  def destroyer_cp=(val)
    write_attribute(:destroyer_cp, val)
    expire_cache("destroyer")
  end

  def destroyer
    get_cache("destroyer", :ttl => 1.day) do
      Level.calculate_single(self.destroyer_cp, self.user.total_datapoints)
    end
  end

  def pathmaker_cp=(val)
    write_attribute(:pathmaker_cp, val)
    expire_cache("pathmaker")
  end

  def pathmaker
    get_cache("pathmaker", :ttl => 1.day) do
      Level.calculate_single(self.pathmaker_cp, self.user.total_datapoints)
    end
  end

  def seer_cp=(val)
    write_attribute(:seer_cp, val)
    expire_cache("seer")
  end

  def seer
    get_cache("seer", :ttl => 1.day) do
      Level.calculate_single(self.seer_cp, self.user.total_datapoints)
    end
  end

  def vigilante_cp=(val)
    write_attribute(:vigilante_cp, val)
    expire_cache("vigilante")
  end

  def vigilante
    get_cache("vigilante", :ttl => 1.day) do
      Level.calculate_single(self.vigilante_cp, self.user.total_datapoints)
    end
  end

  def expire_all
    expire_cache("bedouin")
    expire_cache("benefactor")
    expire_cache("destroyer")
    expire_cache("pathmaker")
    expire_cache("seer")
    expire_cache("vigilante")
  end

  def primary
    case self.primary_class
      when 'bedouin'
        self.bedouin
      when 'benefactor'
        self.benefactor
      when 'destroyer'
        self.destroyer
      when 'pathmaker'
        self.pathmaker
      when 'seer'
        self.seer
      when 'vigilante'
        self.vigilante
      else
        send(highest_level_class)
    end
  end

  def primary_cp
    case self.primary_class
      when 'bedouin'
        self.bedouin_cp
      when 'benefactor'
        self.benefactor_cp
      when 'destroyer'
        self.destroyer_cp
      when 'pathmaker'
        self.pathmaker_cp
      when 'seer'
        self.seer_cp
      when 'vigilante'
        self.vigilante_cp
      when 'shoat'
        self.send("#{highest_level_class}_cp")
      else
        raise InvalidClassnameError
    end
  end

  def dp_status(class_name)
    class_level = send(class_name)
    return "0" if class_level == 20
    cap = Level.req class_level+1, :dp
    current = self.user.total_datapoints

    if( current > cap)
      "0"
    else
      "#{cap - current}"
    end
  end

  def cp_status(class_name)
    class_level = send(class_name)
    return "0" if class_level == 20
    cap = Level.req class_level+1, :cp
    current = send("#{class_name}_cp")

    if(current > cap) # the user doesn't have enough DP
      "0"
    else # the user doesn't have enough cp
      "#{cap - current}"
    end
  end

  def auto_assign_primary
    self.primary_class = highest_level_class
    self.save
  end

  def primary_class=(class_name)
    write_attribute(:primary_class, class_name)
    self.save
  end

  def assign_primary(class_name)
    raise InvalidClassnameError unless ['bedouin','benefactor','destroyer','pathmaker','seer','vigilante'].include? class_name
    self.primary_class = class_name
  end

  def highest_level_class
    levels = Hash['bedouin' => bedouin_cp, 'benefactor' => benefactor_cp, 'destroyer' => destroyer_cp, 'pathmaker' => pathmaker_cp, 'seer' => seer_cp, 'vigilante' => vigilante_cp].sort {|a,b| a[1]<=>b[1]}
    levels.reverse[0][0]
  end

  def dp_percentage(class_name)
    Level.dp_percentage(self.user, class_name)
  end

  def cp_percentage(class_name)
    Level.cp_percentage(self.user, class_name)
  end

  def order_or_chaos?
    chaos = %w(seer destroyer vigilante)
    order = %w(bedouin benefactor pathmaker)

    return "chaos" if chaos.include?(self.primary_class)
    return "order" if order.include?(self.primary_class)
    return "shoat"
  end

#  def recalculate
#    self.bedouin_cp = user.tool_uses.uses(:armor)*Tool.cached_single('armor').classpoints + user.ability_uses.uses(:dodge)*Ability.cached_singe('dodge').classpoints
#    self.benefactor_cp = user.tool_uses.uses(:crates)*Tool.cached_single('crates').classpoints + user.upgrade_uses.uses(:puzzle_crate)*Upgrade.cached_single('puzzle_crate').classpoints + user._ability_uses.uses(:giftcard)*Ability.cached_single('giftcard').classpoints
#    self.destroyer_cp = user.tool_uses.uses(:mines)*Tool.cached_single('mines').classpoints + user.upgrade_uses.uses(:exploding_crate)*Upgrade.cached_single('exploding_crate').classpoints
#    self.pathmaker_cp = user.tool_uses.uses(:lightposts)*Tool.cached_single('lightposts').classpoints + user.missions.size*50 # hardcoded for now
#    self.seer_cp = user.tool_uses.uses(:portals)*Tool.cached_single('portals').classpoints + user.upgrade_uses.uses(:give_dp)*Upgrade.cached_single('give_dp').classpoints
#    self.vigilante_cp = user.tool_uses.uses(:st_nicks)*Tool.cached_single('st_nicks').classpoints + user.tool_uses.uses(:watchdogs)*Tool.cached_single('watchdogs').classpoints
#    self.save
#  end

end
