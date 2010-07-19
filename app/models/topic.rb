# == Schema Information
# Schema version: 20081220201004
#
# Table name: topics
#
#  id          :string(36)    primary key
#  user_id     :string(36)    
#  forum_id    :string(36)    
#  title       :string(255)   
#  description :text          
#  url_name    :string(255)   
#  created_at  :datetime      
#  updated_at  :datetime      
#  is_active   :boolean(1)    default(TRUE)
#  locked      :boolean(1)    
#  pinned      :boolean(1)    
#  posts_count :integer(11)   default(0), not null
#

class Topic < ActiveRecord::Base
  acts_as_activated
  acts_as_cached
  acts_as_subscribeable
  
  after_save :expire_cache

  belongs_to :user
  belongs_to :forum, :counter_cache => true
  has_many :posts, :order => 'posts.created_at ASC', :dependent => :delete_all

  validates_presence_of :title, :description
  validates_length_of :title, :maximum => 255
  validates_uniqueness_of :title, :url_name, :case_sensitive => false

  attr_accessible :title, :description, :forum_id, :user_id

  cattr_reader :per_page
  @@per_page = 25

  def self.cached_find_all
    get_cache( 'topics' ) {
      find(:all)
    }
  end
  
  def self.cached_find_by_url_name(url_name)
    begin
      get_cache( 'topic_' + url_name.to_s ) {
        find( :first, :conditions => { :url_name => url_name }, :include => :posts )
      }
    rescue
      # Ahem, certain topics are too big for cache, so let's catch that here and pull
      # them from the database directly - duncan 08/08/08
      find( :first, :conditions => { :url_name => url_name }, :include => :posts )
    end
  end

  def self.cached_generated(user, showprivate = false)
    if showprivate
      topic_ids = get_cache("#{user}_topics") do
        user.topic_ids
      end
    else
      topic_ids = get_cache("#{user}_public_topics") do
        user.topics.reject{|tp| tp.forum.private?}.map(&:id)
      end
    end
    # Hack, get_caches doesn't respect disabling memcache
    if ActsAsCached.config[:disabled]
      self.find(topic_ids)
    else
      self.get_caches(topic_ids).values
    end
  end

  def to_param
    url_name
  end

  def recent_posts
    Post.find( :all, :include => [ :topic ], :order => 'posts.created_at DESC', :group => 'posts.id', :limit => 5 )
  end
  
  def recently_updated_since(datetime)
    self.posts.count(:all, :conditions => ['posts.created_at > ?', datetime])
  end

  # Create the UUID, url_name and public/private status
  def before_create
    self.id = create_uuid
    self.url_name = create_permalink(self.title)
    self.public = (self.forum.public == false ? 0 : 1)
  end
  
  # Returns the locked status
  def is_locked?
    return self.locked
  end
  
  # Returns the pinned status
  def is_pinned?
    return self.pinned
  end
  
  def activate!
    unless self.is_active
      self.is_active = true
      self.save
    
      Forum.increment_counter("topics_count", self.forum_id)
    end
  end
  
  def deactivate!
    unless not self.is_active
      # Hide all posts
      self.posts.each do |p|
        p.deactivate!
      end
    
      self.is_active = false
      self.save
    
      Forum.decrement_counter("topics_count", self.forum_id)
    end
  end
  
  # Method to sort the topics by the last update.
  def <=>(other_topic)
    s_pinned = pinned == true ? 1 : 0
    o_pinned = other_topic.pinned == true ? 1 : 0
    s_pinned <=> o_pinned && updated_at <=> other_topic.updated_at
  end
end
