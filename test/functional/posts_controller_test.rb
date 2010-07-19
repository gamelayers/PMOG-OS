require File.dirname(__FILE__) + '/../test_helper'
require 'posts_controller'

# Re-raise errors caught by the controller.
class PostsController; def rescue_action(e) raise e end; end

class PostsControllerTest < ActionController::TestCase
  all_fixtures
  
  def setup
    super
  end

  # Marc is a trustee, so this should show non-public topics
  def test_latest_posts_rss_for_trustee
    login_as :marc
    get :latest, { :format => 'rss'}
    assert @response.body =~ /Non public topic/
  end

  # Neb is not a trustee, so this should not show non-public topics
  def test_latest_posts_rss_for_non_trustee
    login_as :neb
    get :latest, { :format => 'rss'}
    assert @response.body !~ /Non public topic/
    assert @response.body =~ /Forum games topic/
  end

  # Should only show public posts
  def test_latest_posts_for_weblog_rss
    login_as :neb
    get :latest, { :format => 'rss'}
    assert @response.body !~ /Non public topic/
    assert @response.body =~ /Forum games topic/
  end
end
