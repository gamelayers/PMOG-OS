class AbilityStatus < ActiveRecord::Base
  belongs_to :user

  class AbilityStatusError < PMOG::PMOGError
  end

  class NoArmorEquipped < AbilityStatusError
    def default
      "Oops! You don't have any armor equipped! (A server error has occured)"
    end
  end

  class NoArmorCharges < AbilityStatusError
    def default
      "Oops! You don't have any charges left on your armor! (A server error has occured)"
    end
  end

  def self.reset_daily_invite_buffs
    update_all("daily_invite_buffs='#{GameSetting.value('Max Daily Buffs Castable')}'")
  end

  def toggle_dodge
    update_attribute(:dodge, !self.dodge.to_bool)
    dodge.to_bool
  end

  def toggle_disarm
    update_attribute(:disarm, !self.disarm.to_bool)
    disarm.to_bool
  end

  def toggle_vengeance
    update_attribute(:vengeance, !self.vengeance.to_bool)
    vengeance.to_bool
  end

  def toggle_armor
    if armor_equipped.to_bool
      user.inventory.deposit :armor
      update_attribute(:armor_equipped, false)
    else
      raise User::InventoryError.new("You don't have any armor!") unless user.inventory.armor > 0
      user.inventory.withdraw :armor
      self.armor_charges = 3 if armor_charges == 0
      self.armor_equipped = true
      self.save
    end
    armor_equipped.to_bool
  end

  def destroy_armor
    user.tool_uses.reward :armor if self.armor_charges > 0
    self.armor_charges = 0
    self.armor_equipped = false
    self.save
  end

  def deplete_armor
    raise NoArmorEquipped unless armor_equipped.to_bool
    self.armor_charges = 1 if armor_charges < 1 # if ppl glitch out, this should fix it

    self.armor_charges -= 1

    if armor_charges == 0
      user.tool_uses.reward :armor
      if user.login == 'jerdu_gains'
        self.armor_charges = 3
      else
        self.armor_equipped = false
      end
    end

    self.save
    armor_charges.to_i
  end

  def before_create
    self.id = create_uuid
  end
end
