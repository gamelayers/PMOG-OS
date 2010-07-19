require File.dirname(__FILE__) + '/../test_helper'

class ForumTest < Test::Unit::TestCase
  
  def test_pmog_only_forum
    forum = Forum.create(:name => "Test PMOG Only Forum", :description => "Testing in progress, nothing to see, move along now.")
    
    assert forum.pmog_only == false, "The forum should not be pmog_only"
    
    forum.pmog_only = true
    
    assert forum.pmog_only == true, "The forum should be pmog_only"
  end
  
end