# == Schema Information
# Schema version: 20081220201004
#
# Table name: forums
#
#  id           :string(36)    primary key
#  title        :string(255)   
#  description  :text          
#  url_name     :string(255)   
#  created_at   :datetime      
#  updated_at   :datetime      
#  position     :integer(11)   
#  pmog_only    :boolean(1)    not null
#  topics_count :integer(11)   default(0), not null
#  public       :boolean(1)    default(TRUE)
#

class Forum < ActiveRecord::Base
  acts_as_cached
  acts_as_list

  after_save :expire_cache

  has_many :topics, :order => 'topics.pinned DESC, topics.updated_at DESC', :dependent => :delete_all
  has_many :posts, :through => :topics

  validates_presence_of :title, :description
  validates_length_of :title, :maximum => 255
  validates_length_of :description, :maximum => 1000
  validates_uniqueness_of :title, :url_name, :case_sensitive => false

  attr_accessible :title, :description

  def recently_updated_since(datetime)
    self.posts.count(:all, :conditions => ['posts.created_at > ?', datetime])
  end

  def self.cached_find_all
    get_cache( 'forums' ) {
      find(:all, :conditions => 'public = 1', :order => 'position ASC')
    }
  end
  
  def self.cached_find_by_url_name(url_name)
    get_cache( "forum_#{url_name}" ) {
      find( :first, :conditions => { :url_name => url_name } )
    }
  end

  def toggle_inactive
    self.inactive = ! self.inactive
    self.save
    self.inactive
  end

  def to_param
    url_name
  end
  
  def private?
    !public?
  end
  
  def private
    private?
  end
  
  def private=(wha)
    self.public = !wha
  end

  def before_create
    self.id = create_uuid
    self.url_name = create_permalink(self.title)
  end
end
