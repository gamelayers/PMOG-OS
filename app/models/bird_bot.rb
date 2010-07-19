# == Schema Information
# Schema version: 20081220201004
#
# Table name: bird_bots
#
#  id          :string(255)   primary key
#  user_id     :string(255)   
#  feed_id     :string(36)    
#  name        :string(255)   
#  url_name    :string(255)   
#  description :text          
#  first_words :string(255)   
#  created_at  :datetime      
#  updated_at  :datetime      
#

# Bird Bots differ from NPCs in that they only have one feed.
class BirdBot < ActiveRecord::Base
  has_many :assets, :as => :attachable
  has_and_belongs_to_many :locations, :join_table => "bird_bots_locations"
  has_and_belongs_to_many :users, :join_table => "bird_bots_users"
  belongs_to :feed
  belongs_to :user

  acts_as_taggable

# At this stage, do not play with url variants. Come back to that.

  validates_uniqueness_of :url_name, :case_sensitive => false
  validates_presence_of :name, :description, :first_words

  attr_accessible :name, :description, :first_words

  # TODO - cache this method and clear that cache when relevant feeds are refreshed
  def latest_messages(options={})
    options = { :order => "created_at DESC", :limit => 10 }.merge(options)
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
    feed.nil? ? [] : feed.messages.find( :all, :order => options[:order], :limit => options[:limit] )
  end

  # Generate a unique name for this BirdBot, for use in the url
  def unique_url_name( name )
    url_name = "#{name.downcase.gsub(/\s+/, '_').gsub(/[^a-zA-Z0-9_]+/, '')}"
    existing = BirdBot.count( :conditions => [ 'url_name = ?', url_name ] )
    while existing > 0
        url_name += '_'
        existing = BirdBot.count( :conditions => [ 'url_name = ?', url_name ] )
    end
    url_name
  end
end
