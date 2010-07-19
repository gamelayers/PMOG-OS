class IndexForums < ActiveRecord::Migration
  def self.up
    execute( "ALTER TABLE forums ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE forums DROP INDEX index_forums_on_id")
    
    execute( "ALTER TABLE topics ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE topics DROP INDEX index_topics_on_id")
    
    execute( "ALTER TABLE posts ADD PRIMARY KEY(id)")
    execute( "ALTER TABLE posts DROP INDEX index_posts_on_id")
    
    add_index :forums, :public

  end

  def self.down
    execute( "ALTER TABLE forums DROP PRIMARY KEY")
    add_index :forums, :id
    
    execute( "ALTER TABLE topics DROP PRIMARY KEY")
    add_index :topics, :id
    
    execute( "ALTER TABLE posts DROP PRIMARY KEY")
    add_index :posts, :id
    
    remove_index :forums, :public
  end
end
