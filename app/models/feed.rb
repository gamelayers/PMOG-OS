# == Schema Information
# Schema version: 20081220201004
#
# Table name: feeds
#
#  id            :string(36)    primary key
#  url           :string(255)   
#  etag          :string(255)   
#  last_modified :datetime      
#  error         :string(255)   
#

# Feeds are data streams/brainz, typically RSS or Atom feeds.
#
# Note that the python script to handle feeds should be refactored to 
# store its urls in the locations database table, but for now it's ok - duncan 29/10/07
class Feed < ActiveRecord::Base
  has_one :bird_bot
  has_many :messages, :order => 'created_at desc'
  has_and_belongs_to_many :npcs, :join_table => 'npcs_feeds'

  # Need to validate this is a proper url too
  validates_format_of :url, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix, :on => :create

  def before_create
    self.id = create_uuid
  end
end
