# == Schema Information
# Schema version: 20081220201004
#
# Table name: npcs
#
#  id          :string(36)    primary key
#  user_id     :string(36)    
#  name        :string(255)   
#  url_name    :string(255)   
#  description :text          
#  first_words :string(255)   
#  created_at  :datetime      
#  updated_at  :datetime      
#

# NPCs have multiple feeds, which they combine into a character.
class Npc < ActiveRecord::Base
  has_many :assets, :as => :attachable
  has_and_belongs_to_many :locations, :join_table => 'npcs_locations'
  has_and_belongs_to_many :feeds, :join_table => 'npcs_feeds'
  has_and_belongs_to_many :users, :join_table => 'npcs_users'
  belongs_to :user

  acts_as_taggable

  # For as and when we need it..
	#has_many :inventory, :as => :slottable, :dependent => :destroy, :extend => NpcInventoryExtension

  validates_uniqueness_of :url_name, :case_sensitive => false
  validates_presence_of :name, :description, :first_words
  
  attr_accessible :name, :description, :first_words

  # TODO - cache this method and clear that cache when relevant feeds are refreshed
  def latest_messages(options={})
    options = { :order => 'created_at DESC', :limit => 10 }.merge(options)
    @latest_messages ||= fetch_latest_messages(options)
  end

  def before_create
    self.id = create_uuid
    self.url_name = unique_url_name(name)
  end

  def to_param
    url_name
  end

  def self.find_by_param(*args)
    find_by_url_name *args
  end

  protected
  # Find the latest messages from this NPCs' brainz and combine them into one hash
  def fetch_latest_messages(options)
    feed_ids = feeds.collect{ |f| f.id }
    Message.find( :all, :conditions => [ 'feed_id IN (?)', feed_ids ], :order => options[:order], :limit => options[:limit] )
  end

  # Generate a unique name for this NPC, for use in the url
  def unique_url_name( name )
    url_name = "#{name.downcase.gsub(/\s+/, '_').gsub(/[^a-zA-Z0-9_]+/, '')}"
    existing = Npc.count( :conditions => [ 'url_name = ?', url_name ] )
    while existing > 0
        url_name += '_'
        existing = Npc.count( :conditions => [ 'url_name = ?', url_name ] )
    end
    url_name
  end
end
