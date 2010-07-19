# all inventories are pretty similar now, so we just need 1 extension
module InventoryExtension

  # accessor for user inventories
  def get_tools_as_hash
    inventory = {}
    TOOLS.each{ |t| inventory[t] = self.send(t)}
    inventory
  end

  # <SINGLE VAR UPDATE FUNCTIONS>
  # AUTO SAVE
  # these are all immediate transactions and .save to the db
  def set(tool, quantity)
    update_attribute(tool.to_sym, quantity)
  end

  def deposit(tool, quantity=1)
    update_attribute(tool.to_sym, send(tool).to_i + quantity)
  end

  # safe withdrawl; never goes below zero
  def withdraw(tool, quantity=1)
    current = send(tool).to_i
    update_attribute(tool.to_sym, current > quantity ? current - quantity : 0)
  end 
  # </SINGLE VAR UPDATE FUNCTIONS>

  # <MULTI UPDATE FUNCTIONS>
  # NO SAVE
  # single variable edit, queues the deposit in the activerecord object (use for batch processing and manually .save at the end)
  def set_ns(tool, quantity)
    return if quantity.nil?
    case tool
      when :armor then self.armor = quantity
      when :crates then self.crates = quantity
      when :datapoints then self.datapoints = quantity
      when :grenades then self.grenades = quantity
      when :lightposts then self.lightposts = quantity
      when :mines then self.mines = quantity
      when :pings then self.pings = quantity
      when :portals then self.portals = quantity
      when :skeleton_keys then self.skeleton_keys = quantity
      when :st_nicks then self.st_nicks = quantity
      when :watchdogs then self.watchdogs = quantity
    end
  end

  def deposit_ns(tool, quantity=1)
    return if quantity.nil?
    case tool
      when :armor then self.armor += quantity
      when :crates then self.crates += quantity
      when :datapoints then self.datapoints += quantity
      when :grenades then self.grenades += quantity
      when :lightposts then self.lightposts += quantity
      when :mines then self.mines += quantity
      when :pings then self.pings += quantity
      when :portals then self.portals += quantity
      when :skeleton_keys then self.skeleton_keys += quantity
      when :st_nicks then self.st_nicks += quantity
      when :watchdogs then self.watchdogs += quantity
    end
  end

  # safe withdrawl; never goes below zero
  def withdraw_ns(tool, quantity=1)
    return if quantity.nil?
    case tool
      when :armor then self.armor = safe_withdraw(tool, quantity)
      when :crates then self.crates = safe_withdraw(tool, quantity)
      when :datapoints then self.datapoints = safe_withdraw(tool, quantity)
      when :grenades then self.grenades = safe_withdraw(tool, quantity)
      when :lightposts then self.lightposts = safe_withdraw(tool, quantity)
      when :mines then self.mines = safe_withdraw(tool, quantity)
      when :pings then self.pings = safe_withdraw(tool, quantity)
      when :portals then self.portals = safe_withdraw(tool, quantity)
      when :skeleton_keys then self.skeleton_keys = safe_withdraw(tool, quantity)
      when :st_nicks then self.st_nicks = safe_withdraw(tool, quantity)
      when :watchdogs then self.watchdogs = safe_withdraw(tool, quantity)
    end
  end
  # </MULTI VAR UPDATE FUNCTIONS>

  # resets all of the user's tools to zero
  def zero_all
    inventory = {}

    ITEMS.each do |item|
      inventory.merge!(item => 0)
    end

    self.update_attributes(inventory)
  end

  private
  def safe_withdraw(tool, quantity)
    current = send(tool).to_i
    current > quantity ? current - quantity : 0
  end

end
