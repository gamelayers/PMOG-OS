require File.dirname(__FILE__) + '/../test_helper'

class PostTest < Test::Unit::TestCase
  all_fixtures
  
  def test_public_post
    user = users(:suttree)
    forum = forums(:games)
    p = forum.topics.first.posts.create(  :body => 'This is a post in a public forum', 
                                          :user_id => user.id)

    assert p
    assert p.valid?
    assert_equal true, p.public
  end
  
  def test_not_public_post
    user = users(:suttree)
    forum = forums(:non_public)
    p = forum.topics.first.posts.create(  :body => 'This is a post in a non-public forum', 
                                          :user_id => user.id)

    assert p
    assert p.valid?
    assert_equal false, p.public
  end
end
