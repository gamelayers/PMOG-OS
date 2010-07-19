class ForumCounterCache < ActiveRecord::Migration
  def self.up
    add_column :forums, :topics_count, :integer, :null => false, :default => 0
    add_column :topics, :posts_count, :integer, :null => false, :default => 0
    add_column :users, :posts_count, :integer, :null => false, :default => 0
    
    Forum.reset_column_information
    Topic.reset_column_information
    User.reset_column_information

    forums = Forum.find(:all, :include => :topics)
    
    forums.each do |forum|
      t_count = forum.topics.count
      for i in 1..t_count
        Forum.increment_counter('topics_count', forum.id)
      end
    end
    
    topics = Topic.find(:all, :include => :posts)
    
    topics.each do |topic|
      p_count = topic.posts.count
      for i in 1..p_count
        Topic.increment_counter('posts_count', topic.id)
      end
    end
    
    users = User.find(:all, :include => :posts)
    users.each do |user|
      p_count = user.posts.count
      for i in 1..p_count
        User.increment_counter('posts_count', user.id)
      end
    end
  end

  def self.down
    remove_column :forums, :topics_count
    remove_column :topics, :posts_count
    remove_column :users, :posts_count
  end
end
