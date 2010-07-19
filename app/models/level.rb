# NOTE: this file is kind of a shitfest now, i apologize
# i've commented out every function that we have depricated (either this refactor or in the past)
# eventually we can clean out all the dead code, but in the mean time i'm leaving it here in case we need to revert easily

# == Schema Information
# Schema version: 20081220201004
#
# Table name: levels
#
#  id                  :string(36)    primary key
#  level               :integer(11)   default(0), not null
#  datapoints          :integer(11)   default(0), not null
#  missions_created    :integer(11)   default(0), not null
#  missions_taken      :integer(11)   default(0), not null
#  created_at          :datetime      
#  updated_at          :datetime      
#  armors_donned       :integer(11)   default(0)
#  crates_deployed     :integer(11)   default(0)
#  lightposts_deployed :integer(11)   default(0)
#  mines_deployed      :integer(11)   default(0)
#  portals_deployed    :integer(11)   default(0)
#  portals_taken       :integer(11)   default(0)
#  rockets_fired       :integer(11)   default(0)
#  walls_deployed      :integer(11)   default(0)
#  st_nicks_attached   :integer(11)   default(0)
#

# Class for handling player levels
class Level < ActiveRecord::Base
  acts_as_cached
  after_save :expire_cache
  #validates_presence_of :datapoints, :missions_taken, :missions_created
  validates_presence_of :datapoints


  # more baked in than a fucking calzone
  @@LVL = []
  @@LVL[1] = { :dp => 0,        :cp => 0}
  @@LVL[2] = { :dp => 20,       :cp => 25}
  @@LVL[3] = { :dp => 100,      :cp => 50}
  @@LVL[4] = { :dp => 300,      :cp => 100}
  @@LVL[5] = { :dp => 600,      :cp => 200}
  @@LVL[6] = { :dp => 1000,     :cp => 300}
  @@LVL[7] = { :dp => 2000,     :cp => 500}
  @@LVL[8] = { :dp => 4000,     :cp => 1000}
  @@LVL[9] = { :dp => 6000,     :cp => 1500}
  @@LVL[10] = { :dp => 12000,   :cp => 2400}
  @@LVL[11] = { :dp => 22000,   :cp => 3300}
  @@LVL[12] = { :dp => 35000,   :cp => 5250}
  @@LVL[13] = { :dp => 50000,   :cp => 7500}
  @@LVL[14] = { :dp => 70000,   :cp => 8750}
  @@LVL[15] = { :dp => 100000,  :cp => 10000}
  @@LVL[16] = { :dp => 150000,  :cp => 15000}
  @@LVL[17] = { :dp => 200000,  :cp => 20000}
  @@LVL[18] = { :dp => 275000,  :cp => 27500}
  @@LVL[19] = { :dp => 375000,  :cp => 37500}
  @@LVL[20] = { :dp => 500000,  :cp => 50000}

  def rebuild_lvl_hash
    #FIXME
  end


  # i'm leaving this as a valid call to preserve the old API but it doesn't really do much anymore
  def self.all_levels_for(user)
    Hash[
      :bedouin => user.user_level.bedouin,
      :benefactor => user.user_level.benefactor,
      :destroyer => user.user_level.destroyer,
      :pathmaker => user.user_level.pathmaker,
      :seer => user.user_level.seer,
      :vigilante => user.user_level.vigilante
    ]
  end

  def self.calculate_single(classpoints, datapoints)
    # skip the second search if the class is lvl1
    (max = binary_level_search(1, 20, classpoints, :cp)) == 1 ? 1 : binary_level_search(1, max, datapoints, :dp)
  end

  def self.binary_level_search low, high, current, type
    mid = -1
    while low < high and low+1 != high do
      mid = low + ((high - low) / 2).to_i # step up half the remaining difference, then floor
      if @@LVL[mid][type] < current
        low = mid
      else
        high = mid
      end
    end

    @@LVL[high][type] > current ? low : high
  end

  def self.req level, type
    @@LVL[level][type]
  end

  # Percentage of this level complete (dp req)
  def self.dp_percentage(user, class_name)
    level = user.user_level.send(class_name)
    # Maxed out for this class
    return 100 if level == 20

    base = @@LVL[level][:dp]
    numerator = user.total_datapoints - base
    denominator = @@LVL[level+1][:dp] - base

    percentage = (numerator.to_f*100/denominator.to_f).to_i
    percentage = 100 if percentage > 100
    percentage
  end

  # Percentage of this level complete (cp req)
  def self.cp_percentage(user, class_name)
    level = user.user_level.send(class_name)
    # Maxed out for this class
    return 100 if level == 20

    base = @@LVL[level][:cp]
    numerator = user.user_level.send("#{class_name}_cp")
    return 0 if numerator == 0
    numerator = numerator - base

    denominator = @@LVL[level+1][:cp] - base

    percentage = (numerator.to_f*100/denominator.to_f).to_i
    percentage = 100 if percentage > 100
    percentage
  end

  # Returns a list of all the datapoint requirements for each level
  def self.list_datapoints_required
    get_cache('list_datapoints_required', :ttl => 1.week) do
      find(:all, :select => 'datapoints').collect{ |l| l.datapoints }
    end
  end

  def before_create
    self.id = create_uuid
  end
end
