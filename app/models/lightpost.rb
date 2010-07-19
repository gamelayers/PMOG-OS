# == Schema Information
# Schema version: 20081220201004
#
# Table name: lightposts
#
#  id          :string(36)    primary key
#  user_id     :string(36)    
#  created_at  :datetime      
#  updated_at  :datetime      
#  location_id :string(36)    
#  description :text          
#

class Lightpost < ActiveRecord::Base
  belongs_to :user
  belongs_to :location
  #belongs_to :old_location
  
  acts_as_taggable
  acts_as_puzzled

  validates_presence_of :location_id, :user_id
  validates_uniqueness_of :location_id, :scope => :user_id, :message => 'You already have a lightpost here.'

  def validate
    errors.add('location_id', 'cannot be null') if location_id == 'null' or location_id.nil?
  end

  def before_create
    self.id = create_uuid
  end
  
  class << self
    def create_and_deposit(current_user, params)
      location = nil
      # first, try to figure out where this post is going
      if !params[:location_id].blank?
        location = Location.find( :first, :conditions => { :id => params[:location_id] } )
        raise Location::LocationNotFound unless !location.nil?
      elsif params[:lightpost] && !params[:lightpost][:location].blank?
        location = Location.find_or_create_by_url(params[:lightpost][:location], :first)
      else
        # nothing specified anywhere, return invalid
        raise Location::InvalidLocation
      end

      upgrades = {} # boolean list of upgrades the user has specified
      total_ping_cost = 0 # int to hold the total cost of those upgrades
      puzzle_post_settings = Upgrade.cached_single('puzzle_post')

      raise DuplicateLightpostError if current_user.lightposts.map {|x| x.location_id}.include?(location.id)
      raise Location::InvalidLocation if Url.unsupported_format?(location.url)
      raise User::InventoryError.new("You don't have any lightposts!") unless current_user.inventory.lightposts >= 1

      if params[:upgrade] # see if we're upgrading at all

        if params[:upgrade][:puzzle].to_bool
          raise User::InsufficientExperienceError.new("You must be a level #{puzzle_post_settings.level} Pathmaker to create a Puzzle Post.") if current_user.levels[:pathmaker] < puzzle_post_settings.level
          raise User::InsufficientPingsError.new("You need #{puzzle_post_settings.ping_cost} Pings to create a Puzzle Post.") if current_user.available_pings < puzzle_post_settings.ping_cost
          raise NoQuestionError if params[:upgrade][:question].nil? || params[:upgrade][:question].empty?
          total_ping_cost += puzzle_post_settings.ping_cost
          upgrades.merge! :puzzle => true
        end

        # total the upgrades bill and check their wallet again
        raise User::InsufficientPingsError if current_user.available_pings < total_ping_cost
      end

      # NOTE END OF RAISED EXCEPTIONS NOTE

      current_user.inventory.withdraw :lightposts
 
      with_this_data = { :location_id => location.id }
      with_this_data[:description] = params[:lightpost][:description] unless params[:lightpost].nil? || params[:lightpost][:description].nil?

      lightpost = current_user.lightposts.create(with_this_data)
      current_user.expire_cache('lightpost_history')
      # give the user a standard lightpost use only if they have no upgrades
      current_user.tool_uses.reward :lightposts if upgrades.empty?

      if upgrades[:puzzle]
        # use acts_as_puzzled to store the puzzle post upgrade
        lightpost.set_puzzle params[:upgrade][:question], params[:upgrade][:answer]
        # give the user a puzzle post use
        current_user.deduct_pings puzzle_post_settings.ping_cost
        current_user.upgrade_uses.reward :puzzle_post
      end

      # If the tag param isn't nil, create tags for each value in the
      # comma separated string.
      create_tag_list_for(lightpost, params) if params[:lightpost]

      # Award class points for deploying a lightpost, or give them a refund

      message = "lit a Lightpost on <a href=\"#{location.url}\">#{Url.caches( :domain, :with => location.url )}</a>"
      
      #NOTE disabled, we don't want lightposts public until they're in a mission
      #Event.record(:user_id => current_user.id,
      #  :context => 'lightpost_deployed',
      #  :message => message )

      lightpost.save

      lightpost
    end
    
    private
    
    def create_tag_list_for(lightpost, params)
      tag_list = params[:lightpost][:tag_list] if params[:lightpost][:tag_list]
      tag_list = params[:lightpost][:tags] if params[:lightpost][:tags]
      if tag_list
        lightpost.save
        lightpost.reload
        lightpost.tag_list = tag_list
      end
    end
  end

  class LightpostError < PMOG::PMOGError
  end

  class DuplicateLightpostError < LightpostError
    def default
      "You already have a lightpost on this url!"
    end
  end

  class NoQuestionError < LightpostError
    def default
      "You need a question for your Puzzle Post!"
    end
  end

end
