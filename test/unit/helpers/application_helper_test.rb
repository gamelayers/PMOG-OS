require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < HelperTestCase

  include ApplicationHelper

  fixtures :users, :user_levels, :tools

  def setup
    super
  end
    
  def test_auto_link_message_logins
    message = '@suttree how are you?'
    assert_equal "<a href='http://thenethernet.com/users/suttree'>suttree</a> how are you?", auto_link_message_logins(message)
    
    message = '@suttree @jah how are you?'
    assert_equal "<a href='http://thenethernet.com/users/suttree'>suttree</a> <a href='http://thenethernet.com/users/jah'>jah</a> how are you?", auto_link_message_logins(message)
    
    message = "there is no at-user"
    assert_equal "there is no at-user", auto_link_message_logins(message)
  end

  def test_link_to_user
    assert_equal false, link_to_user({})

    user = User.find_by_login('suttree')

    assert link_to_user({:user => user}) =~ /a href="\/users\/suttree">suttree<\/a>/i
    assert link_to_user({:user => user, :include_meta_data => true}) =~ /Level/i
    assert link_to_user({:user => user, :include_meta_data => true}) =~ /DP/i
    

    user = users(:marc)
    assert link_to_user({:user => user}) =~ /a href="\/users\/marc">marc<\/a>/i
    assert link_to_user({:user => user, :only_path => false}) =~ /a href="http:\/\/test.host\/users\/marc">marc<\/a>/i
  end

  def test_avatar_link_to_user
    assert_equal false, avatar_link_to_user({})
    
    user = users(:suttree)
    assert avatar_link_to_user({:user => user}) =~ /omg pmog!/i
    assert avatar_link_to_user({:user => user}) =~ /\/images\/shared\/elements\/user_default.jpg/i
    assert avatar_link_to_user({:user => user, :only_path => false}) =~ /images\/shared\/elements\/user_default.jpg/i

    assert avatar_link_to_user({:user => user}) =~ /width="32"/i
    assert avatar_link_to_user({:user => user, :size => 'mini'}) =~ /height="16"/i
    assert avatar_link_to_user({:user => user, :size => 'tiny'}) =~ /width="32"/i
    assert avatar_link_to_user({:user => user, :size => 'small'}) =~ /height="50"/i
    assert avatar_link_to_user({:user => user, :size => 'medium'}) =~ /width="120"/i
    assert avatar_link_to_user({:user => user, :size => 'large'}) =~ /height="400"/i
  end
  
  def test_avatar_path_for_user
    assert_equal false, avatar_link_to_user({})
    user = users(:suttree)
    assert avatar_path_for_user({:user => user}) =~ /\/images\/shared\/elements\/user_default.jpg/
  end

  

  # Pseudo current_user method
  def current_user(login = 'suttree', force_reload = false)
    @current_user = User.find_by_login(login) if @current_user.blank? || force_reload
    @current_user
  end
  
  def logged_in?
    @current_user.logged_in?
  end
end
