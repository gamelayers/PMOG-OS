require File.dirname(__FILE__) + '/../test_helper'
require 'forums_controller'

# Re-raise errors caught by the controller.
class ForumsController; def rescue_action(e) raise e end; end

class ForumsControllerTest < ActionController::TestCase
  all_fixtures
  
  def setup
    super
  end
  
  def test_forum_create_position
    login_as :marc
    
    delete_forums
    
    # Create a new forum using the controller
    post :create, :forum => {:title => "Testing the Controller", :description => "Just an ordinary description", :pmog_only => false}
    
    # Find our newly created forum and assign it to a variable
    forum = Forum.find_by_title("Testing the Controller")
    
    # Check that it exists..
    assert_not_nil forum, "forum shouldn't be nil after the post"
    
    # Check that it got a default position of 1
    assert_equal 1, forum.position, "The forum should have a position of 1"
    
    # Create a second forum using the controller
    post :create, :forum => { :title => "Testing the Controller Dos", :description => "God is in the TV", :pmog_only => false }
    
    # Find our newly created forum and assign it to a variable
    forum_dos = Forum.find_by_title("Testing the Controller Dos")
    
    # Check that it exists...
    assert_not_nil forum_dos, "forum_dos shouldn't be nil after the post"
    
    # Check that it got a position of 2 right after the first one.
    assert_equal 2, forum_dos.position, "forum_dos should have a position of 2"

    # Move the second forum up using the controller
    get :move, { :id => forum_dos.url_name, :move => "move_higher" }
    
    # Reload the attributes
    forum.reload
    forum_dos.reload
    
    # Assume the positions were switched by moving the second forum up.
    assert_equal 1, forum_dos.position, "forum_dos should have a position of 1"
    assert_equal 2, forum.position, "forum should have a position of 2"
    
    # Move the second created forum back down to position 2
    get :move, { :id => forum_dos.url_name, :move => "move_lower" }
    
    # Reload the attributes
    forum.reload
    forum_dos.reload 
    
    # Assume the positions switched again, back to the original order
    assert_equal 1, forum.position, "forum should have a position of 1"
    assert_equal 2, forum_dos.position, "forum_dos should have a position of 2"
  end
  
  # In the event someone tries to be funny and give a new forum a position way out of range..
  def test_forum_normalize_position
    login_as :marc
    
    delete_forums
    
    # Create a new forum using the controller but give it an obscene position
    post :create, :forum => { :title => "Test obscene position", :description => "This isn't a valid position!", :pmog_only => false, :position => 10000 }
    
    # Get the new forum
    forum = Forum.find_by_title("Test obscene position")
    
    # Assert the position is one and not 10000
    assert_equal 1, forum.position, "forum should have a position of 1"
  end

  def test_search_returns_some_results
    get :search, :q => "pbot is stupid"
    assert assigns(:posts)
    assert_equal assigns(:posts).size, 1
  end

  def test_search_results_hides_non_public_matches
    get :search, :q => "A test post in the non public forum"
    assert assigns(:posts)
    assert_equal assigns(:posts), []
  end

  def test_search_results_hides_pmog_only_matches
    get :search, :q => "pmog only forum post"
    assert assigns(:posts)
    assert_equal assigns(:posts), []
  end
  
  private 
  
  def delete_forums
    forums = Forum.find(:all)
    forums.each do |forum|
      forum.destroy
    end
  end
  
end
