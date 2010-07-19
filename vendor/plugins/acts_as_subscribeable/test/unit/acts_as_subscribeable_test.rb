require File.join(File.dirname(__FILE__), '../test_helper')
require File.join(File.dirname(__FILE__), '../test_models/article')
require File.join(File.dirname(__FILE__), '../test_models/user')


class ActsAsSubscribeableTest < Test::Unit::TestCase
    
  def setup
    @article ||= RailsJitsu::Article.create(
      :title => 'A test article',
      :body => 'Test article body data'
    )
    
    @user ||= RailsJitsu::User.create(
      :email => 'test@test.com'
    )
  end
  
  def test_should_ensure_articles_includes_plugin
    assert_nothing_raised {@article.subscriptions}
  end
  
  def test_should_ensure_user_exists
    assert_not_nil @user
  end
  
  def test_should_ensure_user_has_subscription_relationship
    assert_nothing_raised {@user.subscriptions}
  end
  
  def test_should_ensure_add_subscription_creates_subscription
    RailsJitsu::Article.add_subscription(@article, @user)
    assert_equal 1, @user.subscriptions.length
  end
  
  def test_should_ensure_find_subscriptions_for_returns_one_subscription
    RailsJitsu::Article.add_subscription(@article, @user)
    subscriptions = RailsJitsu::Article.find_subscriptions_for(@article)
    assert_equal 1, subscriptions.length
  end
  
  def test_should_ensure_user_subscribed_returns_true_if_subscribed
    RailsJitsu::Article.add_subscription(@article, @user)
    assert true, RailsJitsu::Article.user_subscribed?(@article, @user)
  end
  
  def test_should_ensure_remove_subscription_destroys_subscription
    RailsJitsu::Article.add_subscription(@article, @user)
    subscriptions = RailsJitsu::Article.find_subscriptions_for(@article)
    assert_equal 1, subscriptions.length
    
    RailsJitsu::Article.remove_subscription(@article, @user)
    subscriptions = RailsJitsu::Article.find_subscriptions_for(@article)
    assert_equal 0, subscriptions.length
  end
  
  def test_should_ensure_somehting
    
  end
end