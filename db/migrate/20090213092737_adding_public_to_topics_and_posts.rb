# Adding a public column to the topics and posts helps us denomarmalise the 
# forums data, and should speed up a number of the queries that pull out posts
# based on whether the user can view them or not - duncan 13/02/09
class AddingPublicToTopicsAndPosts < ActiveRecord::Migration
  def self.up
    add_column :topics, :public, :boolean, :default => true
    add_column :posts, :public, :boolean, :default => true
    add_index :posts, [:public, :is_active, :created_at]

    Topic.reset_column_information
    Post.reset_column_information
    
    # Find all the private topics and posts and mark 
    # them as such in the topics and posts tables
    # Note that we don't call topic.save (or post.save) as that
    # triggers the after_update for sending out emails to subscribers
    # of each topic.
    Forum.all(:conditions => {:public => 0}) do |forum|
      forum.topics.all do |topic|
        execute( "UPDATE topics set public = 0 WHERE id = '#{topic.id}'" )
        topic.posts.all do |post|
          execute( "UPDATE posts set public = 0 WHERE id = '#{post.id}'" )
        end
      end
    end
  end

  def self.down
    remove_column :topics, :public
    remove_column :posts, :public
    remove_index :posts, [:public, :is_active, :created_at]
  end
end