# == Schema Information
# Schema version: 20081220201004
#
# Table name: posts
#
#  id         :string(36)    primary key
#  user_id    :string(36)    
#  topic_id   :string(36)    
#  body       :text          
#  created_at :datetime      
#  updated_at :datetime      
#  is_active  :boolean(1)    default(TRUE)
#

class Post < ActiveRecord::Base
  acts_as_activated
  acts_as_cached

  belongs_to :topic, :counter_cache => true
  belongs_to :user,  :counter_cache => true
  
  after_save :expire_cache

  validates_presence_of  :body
  # This will ensure the user exists before adding the record.
  validates_existence_of :user

  attr_accessible :body, :topic_id, :user_id
  
  cattr_reader :per_page
  @@per_page = 25
  
  def topic_title
    return self.topic.nil? ? 'Topic Deleted' : self.topic.title
  end
  
  def author_name
    return self.user.login
  end
  
  def activate!
    unless self.is_active
      self.is_active = true
      self.save
    
      Topic.increment_counter("posts_count", self.topic_id)
    end
  end
  
  def deactivate!
    unless not self.is_active
      self.is_active = false
      self.save
      
      if self.topic.posts_count > 0
        Topic.decrement_counter("posts_count", self.topic_id)
      end
    end
  end
  
  # What page of posts does this post appear on?
  def page
    previous_posts = Post.count(:all, :conditions => ["topic_id = ? AND created_at < ?", self.topic.id, self.created_at])
    return (previous_posts / @@per_page) + 1
  end

  def self.cached_find_all
    get_cache( 'posts' ) {
      find(:all)
    }
  end
  
  def self.cached_find_by_id(id)
    get_cache( 'post_' + self.id.to_s ) {
      find( :first, :conditions => { :id => id } )
    }
  end

  def self.cached_recent_total
    get_cache( 'post_recent_total' ) {
      self.recent_total
    }
  end

  # x posts in the the last 24 hours
  def self.recent_total
    count( :all, :conditions => [ 'created_at BETWEEN ? AND ?', 24.hours.ago.to_s(:db), Time.now.to_s(:db) ] )
  end
  
  # The latest posts, showing private posts if the user is allowed to see them
  def self.latest(current_user, limit = 100)
    Post.find(  :all, 
                :conditions => ('posts.public = 1' unless (current_user and current_user != :false and current_user.admin_or_steward?)),
                :order => 'posts.created_at DESC', 
                :include => { :topic => :forum }, 
                :limit => limit )
  end
  
  # Used by news.pmog.com - shows no private posts at all
  def self.latest_for_weblog
    Post.find(  :all, 
                :conditions => ('posts.public = 1'), 
                :order => 'posts.created_at DESC', 
                :include => { :topic => :forum }, 
                :limit => 100   )
  end

  # Create the UUID and mark the post and public/private
  def before_create
    self.id = create_uuid
    self.public = (self.topic.forum.public == false ? 0 : 1)
  end
  
  # Update the topic updated_at timestamp
  def after_create
    self.topic.updated_at = Time.now.to_s(:db)
    self.topic.save
  end
end
