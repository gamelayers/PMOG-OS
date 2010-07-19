# == Schema Information
# Schema version: 20081220201004
#
# Table name: branches
#
#  id             :string(36)    default(""), not null, primary key
#  mission_id     :string(36)    
#  parent_id      :string(36)    
#  position       :integer(11)   not null
#  branches_count :integer(11)   default(0)
#  location_id    :string(36)    
#  created_at     :datetime      
#  updated_at     :datetime      
#  description    :text          
#  tested         :boolean(1)    
#

require 'avatar_helper'
class Branch < ActiveRecord::Base  
  include AvatarHelper
  belongs_to :mission, :counter_cache => true
  belongs_to :location
  #belongs_to :old_location
  belongs_to :user

  # Make these polymorphic
  has_and_belongs_to_many :bird_bots, :join_table => "branches_bird_bots"
  has_and_belongs_to_many :npcs, :join_table => "branches_npcs"
  has_and_belongs_to_many :missions, :join_table => "branches_missions"
  
  has_one :portal, :conditions => "branch_id is not null" # only mission portals should be included

  acts_as_cached
  acts_as_tree :order => 'branches.position', :counter_cache => true
  # The formatting of the scope below is very important. Any deviation will cause it to break.
  acts_as_list :scope => 'mission_id = \'#{mission_id}\''

  acts_as_puzzled
  
  # habtm instead?
  #
  # remember that each branch with a link is effectively a portal
  #
  #has_many :items, :dependent => :destroy
  #has_many :tools, :dependent => :destroy

  validates_presence_of :location_id, :description

  # Protect internal methods from mass-update.
  attr_accessible :description, :url, :position, :mission_id, :parent_id, :location_id

  @@private_api_fields = []
  @@included_api_associations = [ :mission, :bird_bots, :npcs, :missions, :portal ]

  def self.find_with_associated(id)
    Branch.find( id, :include => [ :mission, :npcs, :bird_bots ], :order => "branches.position asc", :group => "branches.id" )
  end

  # Find any branches that somewhat match +url+
  # Note that this runs on every track hit, so it is cached, but we might
  # want to replcae the Url.variants call with just +url+
  def self.nearby(url)
    Branch.find_by_sql( [ 'SELECT branches.* FROM branches, missions, locations WHERE branches.mission_id = missions.id AND branches.location_id = locations.id and locations.url IN (?) and missions.is_active = ?', Url.variants(url, false), 1 ] )
  end
  
  # The next stop on this +mission+, note the hacky parameter :(
  # You'd think we could just use +position+ here, but for some reason +Branch+ and +acts_as+list+
  # really don't get along. There's a bug with all positions being set to '1', so let's just use
  # created_at and updated_at to find the next and previous branches.
  def next
    unless self.last?
      self.lower_item
    end
  end
  
  # This previous stop on this +mission+, note the hacky parameter :(
  def previous
    unless self.first?
      self.higher_item
    end
  end

  def portal_destination
    self.portal.destination.url unless self.portal.nil?
  end

  # Returns a list of children, grandchildren, great-grandchildren, and so forth. 
  # Code from http://dev.rubyonrails.org/ticket/7574
  def descendants
    children.map(&:descendants).flatten + children
  end

  def before_create
    self.id = create_uuid
  end
  
  # Called after a branch is updated so that changes are reflected to the user
  def after_update
    self.clear_cache
  end
  
  def to_json_overlay(extra_args = {})
    Hash[
      :id => mission.id,
      :user => mission.user.login,
      :avatar => avatar_path_for_user(:user => mission.user, :size => 'tiny'),
      :name => mission.name,
      :url_name => mission.url_name,
      :average_rating => mission.average_rating,
      :nsfw => mission.is_nsfw?
    ].merge(extra_args).to_json
  end
end
