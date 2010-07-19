require File.dirname(__FILE__) + '/../test_helper'

class TopicTest < Test::Unit::TestCase
  all_fixtures
  
  def test_public_topic
    user = users(:suttree)
    forum = forums(:games)
    t = forum.topics.create(  :title => 'Public topic',
                              :description => 'Public topic description',
                              :user_id => user.id )

    assert t
    assert t.valid?
    assert_equal true, t.public
  end
  
  def test_not_public_topic
    user = users(:suttree)
    forum = forums(:non_public)
    t = forum.topics.create(  :title => 'A non public topic',
                              :description => 'Non public topic description',
                              :user_id => user.id )

    assert t
    assert t.valid?
    assert_equal false, t.public
  end
end