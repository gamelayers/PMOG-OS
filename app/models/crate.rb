# == Schema Information
# Schema version: 20081220201004
#
# Table name: crates
#
#  id          :string(36)    primary key
#  user_id     :string(36)
#  location_id :string(36)
#  created_at  :datetime
#  updated_at  :datetime
#  comments    :string(255)
#  context     :string(255)
#  question    :string(255)
#  answer      :string(255)
#  charges     :integer(11)   default(1)
#

class Crate < ActiveRecord::Base
  include FirstValidScope
  belongs_to :location
  #belongs_to :old_location
  belongs_to :user

  acts_as_cached

  has_one :inventory, :as => :owner, :dependent => :destroy, :extend => InventoryExtension
  has_many :dismissals, :as => :dismissable, :dependent => :destroy, :extend => DismissableExtension

  has_one :crate_upgrade, :dependent => :destroy

  validates_presence_of :location_id, :user_id

  # Restricted attributes and included association for JSON output
  cattr_accessor :private_api_fields, :included_api_associations
  @@private_api_fields = []
  @@included_api_associations = [ :inventory ]

  # Setting the context makes the extension render the crate differently.
  @@available_contexts = %w(unlocked puzzle)
  cattr_reader :available_contexts

  def self.create_on_profile(location)
    # NPCs in action!  Thomas Hoggins now benefacts the DP to new shoats.
    comments = <<TEXT
Good day to you, I am Thomas and offer this crate as a welcome to the wonderful community that is The Nethernet. Feel free to add me as an Ally, or send a PMail with any questions you may have.  Welcome, and ENJOY!  - Thomas
TEXT
    crate = Crate.create(:user_id => User.find_by_login('thomas_hoggins').id, :location => location, :comments => comments)
    Inventory.create(:owner_id => crate.id, :owner_type => 'Crate', :datapoints => 200)
  end

  # NOTE the order of events in this method is HUGELY important, don't refactor without checking the consequences (or at least running rake)
  def self.create_and_deposit(current_user, location, params)
    begin
      raise NoCrateToDeposit unless current_user.inventory.crates > 0
      # Straight away, let's deduct a crate from the user inventory. This way, if any error happens after this, we can put it back.
      # If this error comes after any other error, then we can't credit the user with the crate that is deducted for errors previous to this.
      current_user.inventory.crates -= 1

      raise InvalidParameters unless params && !params.empty?

      # check base crate level requirements
      crate_settings = Tool.cached_single(:crates)

      if current_user.levels[:benefactor] < crate_settings.level
        if current_user.login == 'thomas_hoggins'
          current_user.user_level.benefactor_cp = 100000
        else
          raise User::InsufficientExperienceError.new("You must be a level #{crate_settings.level} Benefactor in order to stash Crates")
        end
      end

      stealth = false
      # if the crate isn't an evercrate, we want 1 copy of each event
      charges = 1
      # untill specified, we spend no pings on upgrades
      total_ping_cost = 0

      # validate the upgrade-specific params independently, and before the creation of the actual crate record
      if(!params[:upgrade].nil?)
        #NOTE i folded the validation of upgrade parameters into the main crate constructor because you CANT do all the math properly from the other context now that you can crate pings

        if params[:upgrade][:locked] && params[:upgrade][:locked].to_bool
          puzzle_crate_settings = Upgrade.cached_single('puzzle_crate')
          raise User::InsufficientExperienceError.new("You must be a level #{puzzle_crate_settings.level} Benefactor to lock a Crate") if current_user.levels[:benefactor] < puzzle_crate_settings.level
          raise CrateUpgrade::PuzzleCrate_NoQuestion unless params[:upgrade][:question] && !params[:upgrade][:question].blank?
          total_ping_cost += puzzle_crate_settings.ping_cost
          locked = true
        end

        if params[:upgrade][:charges] && params[:upgrade][:charges].to_i > 0
          raise CrateUpgrade::EverCrate_OnProfile if location.is_user_profile
          charges = params[:upgrade][:charges].to_i
          raise CrateUpgrade::EverCrate_NoCharges if charges <= 1 # ever crates require at least 2 charges
          ever_crate_settings = Upgrade.cached_single(:ever_crate)
          raise User::InsufficientExperienceError.new("You must be a level #{ever_crate_settings.level} Benefactor in order to stash Ever Crates") if current_user.levels[:benefactor] < ever_crate_settings.level
          total_ping_cost += ever_crate_settings.ping_cost
          ever = true
        end

        if params[:upgrade][:exploding] && params[:upgrade][:exploding].to_bool
          exploding_crate_settings = Upgrade.cached_single('exploding_crate')
          # if we have an exploding crate that means no loot (which also means we don't need to sum these mines into the tool total later when checking validity)
          raise CrateUpgrade::ExplodingCrate_NoMines unless current_user.inventory.mines >= exploding_crate_settings.mine_cost * charges
          raise User::InsufficientExperienceError.new("You must be a level #{exploding_crate_settings.level} Destroyer to build an Exploding Crate") if current_user.levels[:destroyer] < exploding_crate_settings.level
          total_ping_cost += exploding_crate_settings.ping_cost * charges
          exploding = true
        end

        if params[:upgrade][:stealth].to_bool
          stealth_settings = Upgrade.cached_single('stealth_crate')
          raise User::InsufficientExperienceError.new("You must be a Level #{stealth_settings.level} Benefactor in order to lay a Stealth Crate") if current_user.levels[:benefactor] < stealth_settings.level
          raise User::InsufficientPingsError.new("You don't have enough pings to create a Stealth Crate!") if current_user.available_pings < stealth_settings.ping_cost
          total_ping_cost += stealth_settings.ping_cost
          #hackish but i'm just leaving this here for now until i have a chance to overhaul all of this and ditch crate_upgrade entirely
          current_user.upgrade_uses.reward :stealth_crate
          stealth = true
        end

        raise User::InsufficientPingsError.new("You do not have enough pings for these upgrades") if current_user.available_pings < total_ping_cost
        raise CrateUpgrade::NoUpgradeSpecified if !exploding && !locked && !ever && !stealth
        upgraded = true
      end
      # </INITIALIZATION>

      # figure out exactly what we're dealing with
      total_datapoints = params[:crate][:datapoints].to_i
      total_pings = params[:crate][:pings].to_i
      total_tools = 0
      unless params[:crate][:tools].nil?
        params[:crate][:tools].each do |tool,total|
          total = total.to_i
          total_tools += total.to_i
        end
      end
      total_combined = total_datapoints + (total_pings * 2) + (total_tools * 100)

      raise EmptyCrateError.new if total_combined <= 0 && !exploding
      raise CrateUpgrade::ExplodingCrate_HasTools if exploding && total_combined > 0

      # make sure the crate won't burst at the seams
      raise User::InsufficientDPError.new("You can't stash more datapoints than you have!") unless current_user.datapoints >= total_datapoints
      raise CrateUpgrade::EverCrate_TooManyCharges unless current_user.datapoints >= total_datapoints * charges
      raise User::InsufficientPingsError.new("You can't stash more pings than you have!") unless current_user.available_pings >= total_pings
      raise CrateUpgrade::EverCrate_TooManyCharges unless current_user.available_pings >= total_pings * charges
      raise User::InsufficientPingsError.new("You don't have enough pings to fill your Crate and still afford the upgrades you selected.") unless current_user.available_pings >= (total_pings * charges) + total_ping_cost
      raise InvalidCrateInventory_NegativeDatapoints unless total_datapoints >= 0
      raise InvalidCrateInventory_NegativePings unless total_pings >= 0
      params[:crate][:tools].each do |tool, total|
        # The param values are strings and the math won't wash
        total = total.to_i
        raise User::InsufficientToolsError.new("You do not have enough tools to fill this Crate.") if current_user.inventory.send(tool.to_sym) < total
        raise CrateUpgrade::EverCrate_TooManyCharges if current_user.inventory.send(tool.to_sym) < (total * charges)
        raise InvalidCrateInventory_NegativeTools if total < 0
      end unless params[:crate][:tools].nil?

      # stop the various types of overfilling/underfilling
      raise InvalidCrateInventory_TooManyDatapoints unless total_datapoints <= 1000
      raise InvalidCrateInventory_TooManyPings unless total_pings <= 500
      raise InvalidCrateInventory_TooManyTools unless total_tools <= 10
      valid_dp = true if total_datapoints >= 10
      valid_pings = true if total_pings >= 5
      valid_tools = true if total_tools >= 2
      raise InvalidCrateInventory_NotEnoughLoot unless valid_dp or valid_pings or valid_tools or exploding

      ### VALIDATION COMPLETE ###

      # Now create and put stuff in the crate, taking it from the users inventory
      crate = Crate.create(:user_id => current_user.id, :location => location, :stealth => stealth)
      crate.comments = params[:crate][:comments]

      if upgraded
        CrateUpgrade.create_and_use(crate, params[:upgrade])
      else
        # Reward basic crate classpoints
        current_user.tool_uses.reward :crates
      end

      if stealth
        Event.record :context => 'stealth_crate_stashed',
          :user_id => current_user.id,
          :message => "stashed a Stealth Crate somewhere on the Interwebs"
      else
        # Note that we still reveal the domain of the stashed crate as a couple of PMOG mods rely on this
        Event.record :context => 'crate_stashed',
          :user_id => current_user.id,
          :message => "stashed a Crate somewhere on <a href=\"http://#{Url.host(location.url)}\">#{Url.host(location.url)}</a>"
      end

      # <CRATE CONTENTS>
      # we can deduct tools from the user safely at this point, we already validated inventories (assuming safe concurrency)
      Inventory.create(:owner_id => crate.id, :owner_type => 'Crate')

      params[:crate][:tools].each do |tool, total|
        # The param values are strings and the math won't wash
        total = total.to_i
        current_user.inventory.withdraw(tool, total * charges) # if this throws an error, it won't have deleted that tool from the user
        crate.inventory.deposit(tool, total) # depositing without save (reduce # of INSERTs)
      end unless params[:crate][:tools].nil?

      # Deposit datapoints
      if total_datapoints > 0
        crate.inventory.datapoints = total_datapoints
        current_user.deduct_datapoints(total_datapoints * charges)
      end

      # Deposit pings
      if total_pings > 0
        crate.inventory.pings = total_pings
        current_user.deduct_pings(total_pings * charges)
      end

      # don't forget to charge for upgrades
      current_user.deduct_pings(total_ping_cost)

      crate.inventory.save
      crate.charges = charges
      # </CRATE CONTENTS>

      crate.save
      return crate
    rescue NoCrateToDeposit
      # very first error, don't refund the crate
      raise
    rescue PMOG::PMOGError => e
      current_user.inventory.deposit :crates
      raise
    end
  end

  # Find a pseudo-random crate. Currently only rejects crates on pmog.com, but this could
  # be extended to include other requirements.
  def self.find_first_random_and_appropriate_for(current_user)
    crates = Crate.find(:all, :order => 'created_at DESC', :include => :location, :limit => 50)
    crates.reject{ |c|
      c.location.nil? ||
      c.location.is_pmog_url  ||
      c.dismissals.dismissed_by?(current_user) ||
      current_user.daily_domains.recently_visited?(c.location)
    }.rand
  end

  def contents
    contents = {}
    ITEMS.each do |item|
      val = self.inventory.send(item).to_i
      contents[item.to_s] = val if val > 0
    end
    contents['comment'] = self.comments
    contents['user'] = self.user.login

    return contents
  end

  # A JSON representation of a 'found' crate
  def to_json_overlay(extra_args = {})
    @hash = Hash[
      :id => id,
      :location_id => self.location.id,
      :user => user.login
    ]

    @hash.merge!(Hash[:context => "ever"]) if self.is_upgraded? && self.crate_upgrade.ever_crate.to_bool
    @hash.merge!(Hash[:context => "puzzle", :question => self.crate_upgrade.puzzle_question]) if self.is_upgraded? && !self.crate_upgrade.puzzle_question.blank?

    @hash.merge(extra_args).to_json
  end

  def is_upgraded?
    !crate_upgrade.nil?
  end

  # Take all the items from the crate, place them in the users inventory and destroy the crate
  # Note that looted datapoints aren't added to your overall total since they don't count towards levelling
  def loot(current_user, params = {})
    raise CrateNotFound if dismissals.dismissed_by? current_user

    # grab the contents now.  this is what we're returning for display so this way we can just edit it directly as the return data changes
    crate_contents = self.contents

    event_crate_text = "Crate on <a href=\"#{self.location.url}\">#{Url.host(self.location.url)}</a>"
    event_crate_text = "Stealth Crate" if self.stealth

    # we overwrite stuff in this hash contextually and then generate the event itself at the end once we know we're valid
    event_data = {:context => "crate_looted",
      :user_id => current_user.id,
      :recipient_id => self.user.id,
      :message => "just looted <a href=\"#{self.pmog_host}/users/#{self.user.login}\">#{self.user.login}'s</a> #{event_crate_text}",
      :details => "You left this Crate at <a href=\"#{self.location.url}\">#{self.location.url}</a> on #{self.created_at.to_s}."}

    # first, validation and contextual message building
    if is_upgraded?
      ### PUZZLES ###
      if !self.crate_upgrade.puzzle_question.blank?
        if(params[:skeleton_key] && params[:skeleton_key].to_bool)
          raise CrateUpgrade::PuzzleCrate_NoSkeletonKeys unless current_user.inventory.skeleton_keys >= 1

          current_user.tool_uses.reward :skeleton_keys
          current_user.inventory.withdraw :skeleton_keys

          crate_contents.merge! :answer => crate_upgrade.puzzle_answer, :icon => "skeleton_key"

          event_data.merge! :context => 'skeleton_key_used',
            :message => "cracked <a href=\"#{self.pmog_host}/users/#{self.user.login}\">#{self.user.login}'s</a> Puzzle Crate with a Skeleton Key"
        else
          raise CrateUpgrade::PuzzleCrate_NoAnswer unless params[:answer]
          raise CrateUpgrade::PuzzleCrate_WrongAnswer unless params[:answer] && crate_upgrade.is_answer?(params[:answer])

          crate_contents.merge! :icon => "puzzle_crate"

          event_data.merge! :context => 'puzzle_crate_looted',
            :message => "solved <a href=\"#{self.pmog_host}/users/#{self.user.login}\">#{self.user.login}'s</a> Puzzle Crate"
        end
      end

      ### EVER CRATES ###
      # We have to do ever crates before exploding ones, or else the extension won't show the exploding crate at all.
      if self.crate_upgrade.ever_crate
        # only 1 loot per this user
        self.dismissals.dismiss current_user unless self.dismissals.dismissed_by? current_user

        crate_contents.merge! :icon => "ever_crate"
      end

      ### EXPLODING CRATES ###
      if self.crate_upgrade.exploding
        ### ARMOR ###
        if current_user.is_armored?
          current_user.deplete_armor

          crate_contents.merge! :icon => "armor"

          event_data.merge! :context => 'exploding_crate_deflected',
            :message => "foiled <a href=\"#{self.pmog_host}/users/#{self.user.login}\">#{self.user.login}'s</a> Exploding Crate with Armor"
        ### EXPLODING SUCCESS ###
        else
          # ouch it hurt me
          damage = Upgrade.cached_single('exploding_crate').damage
          current_user.deduct_datapoints(damage)

          # Check to see if some idiot rival is the one who set off your trap
          self.user.reward_pings Ping.value("Damage Rival") if self.user.buddies.rivaled_with? current_user

          crate_contents.merge! :icon => "explosion", :damage => damage

          event_data.merge! :context => 'exploding_crate_detonated',
            :message => "singed their fingers on <a href=\"#{self.pmog_host}/users/#{self.user.login}\">#{self.user.login}'s</a> Exploding Crate"
        end
      end
    end

    if self.stealth
      event_data[:context] = "stealth_crate_looted"
    end

    ### VALIDATION COMPLETE ###

    # transfer the goods out of all non-explosive crates
    unless(is_upgraded? && self.crate_upgrade.exploding)
      ITEMS.each do |item|
        if item == :pings
          current_user.reward_pings self.inventory.pings.to_i, false
        elsif item == :datapoints
          current_user.reward_datapoints self.inventory.datapoints.to_i, false
        else
          current_user.inventory.deposit_ns(item, self.inventory.send(item).to_i)
        end
      end
      current_user.inventory.save

      # give pings to the benefactor if the looter is an ally
      self.user.reward_pings Ping.value('Aid Ally') if self.user.buddies.allied_with? current_user

      current_user.expire_cache(current_user.id)
      current_user.save(false)
    end

    Event.record event_data

    # all crates use the same count down system (normal just has 1 charge)
    self.charges -= 1

    # expire ever crates as the last outgoing message, also do it before we destroy
    if(self.charges == 0 && is_upgraded? && self.crate_upgrade.ever_crate.to_bool)
      Event.record :context => "ever_crate_expired",
        :user_id => self.user.id,
        :recipient_id => self.user.id,
        :message => "said goodbye to their Ever Crate"
    end

    self.charges == 0 ? self.destroy : self.save

    crate_contents
  end

  def before_create
    self.id = create_uuid
  end

  class << self
    def stashed_this_week
      get_cache('stashed_this_week') do
        raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
        connection = self.connection
        establish_connection configurations['slave']
        data = find(:all, :select => 'COUNT(id) AS count, DATE(created_at) AS date', :conditions => ['created_at BETWEEN ? AND ?', 0.weeks.ago.at_beginning_of_week.to_time, 0.weeks.ago.at_end_of_week.to_time], :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        self.connection = connection
        data
      end
    end

    def stashed_last_week_
      get_cache('stashed_last_week') do
        raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
        connection = self.connection
        establish_connection configurations['slave']
        data = find(:all, :select => 'COUNT(id) AS count, DATE(created_at) AS date', :conditions => ['created_at BETWEEN ? AND ?', 1.week.ago.at_beginning_of_week.to_time, 1.week.ago.at_end_of_week.to_time], :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        self.connection = connection
        data
      end
    end

    def stashed_all_time
      get_cache('stashed_all_time') do
        raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
        connection = self.connection
        establish_connection configurations['slave']
        data = find(:all, :select => 'COUNT(id) AS count, DATE(created_at) AS date', :conditions => ['created_at > ?', 0], :group => 'DATE(created_at)', :order => 'DATE(created_at) DESC' )
        self.connection = connection
        data
      end
    end

    def looted_this_week
      get_cache('looted_this_week') do
        raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
        connection = self.connection
        establish_connection configurations['slave']
        tool_id = Tool.cached_single('crates')
        data = ToolUse.find(:all, :select => 'COUNT(user_id) AS count, DATE(created_at) AS date', :conditions => ['tool_id = ? AND created_at BETWEEN ? AND ?', tool_id, 0.weeks.ago.at_beginning_of_week.to_time, 0.weeks.ago.at_end_of_week.to_time], :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        self.connection = connection
        data
      end
    end

    def looted_last_week
      get_cache('looted_last_week') do
        raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
        connection = self.connection
        establish_connection configurations['slave']
        tool_id = Tool.cached_single('crates')
        data = ToolUse.find(:all, :select => 'COUNT(user_id) AS count, DATE(created_at) AS date', :conditions => ['tool_id = ? AND created_at BETWEEN ? AND ?', tool_id, 1.week.ago.at_beginning_of_week.to_time, 1.week.ago.at_end_of_week.to_time], :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        self.connection = connection
        data
      end
    end

    def looted_all_time
      get_cache('looted_all_time') do
        raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
        connection = self.connection
        establish_connection configurations['slave']
        tool_id = Tool.cached_single('crates')
        data = ToolUse.find(:all, :select => 'COUNT(user_id) AS count, DATE(created_at) AS date', :conditions => ['tool_id = ?', tool_id], :group => 'DATE(created_at)', :order => 'DATE(created_at) ASC' )
        self.connection = connection
        data
      end
    end
  end

  #FIXME all of these crate errors should probably go in a different file.  i have them here for now until i figure out/have the time to do it cleanly.

  # parent for all crate-specific errors ( NOT for user errors re: crates)
  class CrateError < PMOG::PMOGError
  end

  class NoCrateToDeposit < User::InventoryError
    def default
      "You don't have any Crates to stash!  Head to the shoppe first."
    end
  end

  # parentless bad params error for create_and_deposit
  class InvalidParameters < CrateError
    def default
      "Invalid parameters specified for your Crate, please try again."
    end
  end

  # parent for all errors pertaining to invalid crate inventories; thrown during create_and_deposit
  class InvalidCrateInventory < CrateError
    def default
      "There was an error creating your Crate due to invalid contents.  Please try again."
    end
  end

  class EmptyCrateError < InvalidCrateInventory
    def default
      "You cannot stash empty Crates"
    end
  end

  class InvalidCrateInventory_NegativeDatapoints < InvalidCrateInventory
    def default
      "You must stash a positive number of datapoints in a Crate."
    end
  end

  class InvalidCrateInventory_NegativePings < InvalidCrateInventory
    def default
      "You must stash a positive number of pings in a Crate."
    end
  end

  class InvalidCrateInventory_NegativeTools < InvalidCrateInventory
    def default
      "You must stash a positive number of tools in a Crate."
    end
  end

  class InvalidCrateInventory_TooManyDatapoints < InvalidCrateInventory
    def default
      "You may stash a maximum of 1000 datapoints in a Crate."
    end
  end

  class InvalidCrateInventory_TooManyPings < InvalidCrateInventory
    def default
      "You may stash a maximum of 500 pings in a Crate."
    end
  end

  class InvalidCrateInventory_TooManyTools < InvalidCrateInventory
    def default
      "You may stash a maximum of 10 tools in a Crate."
    end
  end

  class InvalidCrateInventory_NotEnoughLoot < InvalidCrateInventory
    def default
      "You must stash a minium of 10 datapoints, 5 pings or 2 tools in a Crate."
    end
  end

  # parent for all loot related errors
  class CrateLootError < CrateError
    def default
      "Sorry, there was a problem looting that Crate."
    end
  end

  class CrateNotFound < CrateError
    def default
      "Sorry, we couldn't find the Crate you were looking for.  Perhaps it was already looted?"
    end
  end

end
