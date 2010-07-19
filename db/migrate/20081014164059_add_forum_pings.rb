class AddForumPings < ActiveRecord::Migration
  def self.up
    Ping.create(:name => 'forum_reply', :points => 2)
    Ping.create(:name => 'forum_topic', :points => 10)
  end

  def self.down
  end
end
