class GuideController < ApplicationController
  def index
    @page_title = 'A Guide to '
    @pmog_classes = PmogClass.find(:all, :order => 'name')
    @tools = Tool.find(:all, :order => '`character`')
    @upgrades = Upgrade.find(:all, :order => 'name')
    @abilities = Ability.find(:all, :order => 'name')
    @badges = Badge.caches(:find, :withs => [ :all, {:order => 'name ASC'}])
  end

  def gameplay
    @page_title = 'Gameplay'
  end
  
  def arsenal
  	@page_title = "An Arsenal of Tools, Upgrades and Abilities on "
  end
  
  def classes
    @page_title = 'A Listing of Player Classes on '
    @pmog_classes = PmogClass.find(:all, :order => 'name')
    if params[:id].blank?
      @pmog_classes = PmogClass.find(:all)
      render :action => :classes
    else
      @pmog_class = PmogClass.find( :first, :conditions => { :name => params[:id].pluralize } ) 
      @page_title = @pmog_class.name.humanize + ", a Player Class on "
      render :action => 'classes/show'
    end
  end
  
  def tools
    @tools = Tool.cached_multi
    @upgrades = Upgrade.cached_multi
    @abilities = Ability.cached_multi
    if params[:id].blank?
      @page_title = 'The Tools of '
      render :action => :tools
    else
      @tool = Tool.cached_single(params[:id])
      raise ActiveRecord::RecordNotFound if @tool.nil?
      @page_title = @tool.name.humanize + ", a Tool on "
      render :action => 'tools/show'
    end
  end

  def upgrades
    @upgrades = Upgrade.cached_multi
    if params[:id].blank?
      @page_title = 'Upgrades in '
      render :action => :upgrades
    else
      @upgrade = Upgrade.cached_single(params[:id])
      raise ActiveRecord::RecordNotFound if @upgrade.nil?
      @page_title = @upgrade.name.humanize + ", a Tool Upgrade on "
#      @upgrade_uses = UpgradeUse.total(@upgrade)
      render :action => 'upgrades/show'
    end
  end

  def abilities
    @abilities = Ability.cached_multi
    if params[:id].blank?
      @page_title = 'Abilities in '
      render :action => :abilities
    else
      @ability = Ability.cached_single(params[:id])
      raise ActiveRecord::RecordNotFound if @ability.nil?
      @page_title = @ability.name.humanize + ", an Ability on "
      @max_uses_per_day = GameSetting.value('Max Daily Buffs Castable')
#      @ability_uses = AbilityUse.total(@ability)
      render :action => 'abilities/show'
    end
  end
  
  def badges
    if params[:id].blank?
      @page_title = 'Badges on '
      @badges = Badge.find(:all, :select => "badges.*, count(badgings.user_id) AS user_count", :joins => "INNER JOIN badgings ON badgings.badge_id = badges.id", :group => "badges.id", :order => "name ASC")
      render :action => 'badges/index'
    else
      @badges = Badge.caches(:find, :withs => [ :all, {:order => 'name ASC'}])
      @badge = Badge.caches( :find_by_url_name, :with => params[:id] )
      raise ActiveRecord::RecordNotFound if @badge.nil?
      @page_title = @badge.name + ' Badge on '
      render :action => 'badges/show'
    end
  end
  
  def lore
    @page_title = 'Lore in the Codex on '
    if params[:id].blank?
      render :action => 'lore/index'
    else
      render :action => 'lore/' + params[:id]
    end
  end
  
   def characters
    @page_title = 'Characters on '
    if params[:id].blank?
      render :action => 'characters/index'
    else
      render :action => 'characters/' + params[:id]
    end
  end
  
  def rules
    case params[:id]
      when 'datapoints' 
        @page_title = 'Datapoints, a Currency in the Rules of '
        @dp_per_mission = GameSetting.value("DP Per Mission").to_i
        @dp_per_portal = GameSetting.value("DP Per Portal").to_i
        @dp_per_hour = GameSetting.value("DP Per Hour").to_i
      when 'pings' 
        @page_title = 'Pings, a Social Currency, in the Rules of '
      when 'classpoints'
        @page_title = 'Classpoints in the Rules of '
      when 'nsfw'
        @page_title = 'Not Safe for Work Content on '
      when 'stewards'
        @page_title = 'Stewards on '
      when 'trustees'
        @page_title = 'Trustees on '
      when 'levels'
        @page_title = 'Levels and Leveling up on '
      when 'order'
        @page_title = 'The Faction of Order on '
      when 'chaos'
        @page_title = 'The Faction of Chaos on '
      when 'missions'
        @page_title = 'Explaining Missions on '
      when 'allies'
        @page_title = 'Allies, trusted players on '
      when 'rivals'
        @page_title = 'Rivals, your foes on '
      when 'irc'
        @page_title = 'IRC Conduct and Consequences on '
      when 'terms'
        @page_title = 'Terms of Service on '
      when 'community'
        @page_title = 'Community Standards and Expectations on '
      when 'recruit' 
        @page_title = 'Recruiting more Players to '
      else
        @page_title = 'The Rules of '
    end

    @levels = Level.find(:all)
    # Tools is more or less generic for items that go in the dropdown. Included tools and mission counts.
    @tools = Tool.find(:all).collect {|t| [[t.name.humanize],[t.url_name]]}
    @tools << ['Taken Missions', 'taken']
    @tools << ['Generated Missions', 'generated']
    if params[:id].blank?
      render :action => 'rules/index'
    else
      render :action => 'rules/' + params[:id]
    end
  end

# out of date  
#  def level_req_select
#    tool = params[:level][:tool]
#    levels = Level.find(:all)
#    case tool
#    when 'crates' then @tool_count = levels.collect{|l| [l.level, l.crates_deployed]}
#    when 'lightposts' then @tool_count = levels.collect{|l| [l.level, l.lightposts_deployed]}
#    when 'mines' then @tool_count = levels.collect{|l| [l.level, l.mines_deployed]}
#    when 'portals' then @tool_count = levels.collect{|l| [l.level, l.portals_deployed]}
#    when 'rockets' then @tool_count = levels.collect{|l| [l.level, l.rockets_fired]}
#    when 'walls' then @tool_count = levels.collect{|l| [l.level, l.walls_deployed]}
#    when 'armor' then @tool_count = levels.collect{|l| [l.level, l.armors_donned]}
#    when 'st_nicks' then @tool_count = levels.collect{|l| [l.level, l.st_nicks_attached]}
#    when 'taken' then @tool_count = levels.collect{|l| [l.level, l.missions_taken]}
#    when 'generated' then @tool_count = levels.collect{|l| [l.level, l.missions_created]}
#    end
#  end
  
  def support
    @page_title = 'Support for '
    if params[:id].blank?
      render :action => 'support/index'
    else
      render :action => 'support/' + params[:id]
    end
  end
  
  # These two methods are just redirects from the old 2008 design
  def associations
    redirect_to :action => 'classes', :status => 301
  end
  
  def appendices
    redirect_to :action => 'rules', :status => 301
  end
end
