require File.dirname(__FILE__) + '/../test_helper'

class LocationTest < Test::Unit::TestCase
  fixtures :locations, :users

  def test_user_specific_items
    @user = users(:suttree)

    # Items on these pages should only be shown to their owners
    [ 'http://pmog.com/users/cappy', 'pmog.com/users/justin', 'dev.pmog.com/users/marc', 'ext.pmog.com/users/merci', 'http://ext.pmog.com/users/littledonkey/' ].each do |url|
      @location = Location.find_or_create_by_url( Url.normalise(url) )
      assert_equal true, @location.user_specific_item(@user)
    end

    # These pages should just fail
    [ 'news.bbc.co.uk', 'www.suttree.com', 'en.wikipedia.org/pmog.com/users/suttree', 'pmog.com', 'http://ext.pmog.com', 'dev.pmog.com', 'http://pmog.com/users' ].each do |url|
      @location = Location.find_or_create_by_url( Url.normalise(url) )
      assert_equal false, @location.user_specific_item(@user)
    end
    
    # Since we're the user 'suttree', we should be able to view any items on this url
    url = 'http://pmog.com/users/suttree'
    @location = Location.find_or_create_by_url( Url.normalise(url) )
    assert_equal false, @location.user_specific_item(@user)
    
    # This shouldn't allow the user suttree to access items on the profile of a user with the name suttreeisme.
    # i.e. There should be exact username matching.
    url = 'http://pmog.com/users/suttreeisme'
    @location = Location.find_or_create_by_url( Url.normalise(url) )
    assert_equal true, @location.user_specific_item(@user)
  end
  
  # Certain pmog urls cannot have tools placed on them
  # - we use @location.protected_by_pmog to verify that a url is part of pmog
  # - we use check_for_pmog_profile_page to return the matching user login
  def test_protected_by_pmog
    # All profile pages are fair game. Note that they will initially be considered
    # protected, but a subsequent check to +check_for_pmog_profile_page+ will tell
    # us whether we can mine them
    [ 'http://pmog.com/users/cappy', 'pmog.com/users/justin', 'dev.pmog.com/users/marc', 'ext.pmog.com/users/merci', 'http://ext.pmog.com/users/littledonkey/', 'http://localhost:3000/users/duncan/' ].each do |url|
      @location = Location.find_or_create_by_url( Url.normalise(url) )
      assert_equal true, @location.protected_by_pmog?
      assert_not_equal nil, @location.check_for_pmog_profile_page
    end

    # All other pages are off limits
    # - that includes user message pages
    [ 'http://pmog.com/learn', 'pmog.com/codex', 'dev.pmog.com/shoppe', 'ext.pmog.com/forums', 'http://ext.pmog.com/tools/mines/', 'http://localhost:3000/missions', 'http://localhost:3000/events?page=5', 'http://pmog.com/users/suttree/messages', 'http://dev.pmog.com/users/merci/messages/' ].each do |url|
      @location = Location.find_or_create_by_url( Url.normalise(url) )
      assert_equal true, @location.protected_by_pmog?
    end
  end
  
  # Test the training area of pmog where new users can deploy mines on pmog.com
  def test_minefields
    minefield_url = 'http://pmog.com/learn/mines'
    portalfield_url = 'http://localhost:3000/learn/portals'

    # Note that you can only deploy mines on the learn/mines page,
    @location = Location.find_or_create_by_url( Url.normalise(minefield_url) )
    assert_equal true, @location.minefield?

    @location = Location.find_or_create_by_url( Url.normalise(portalfield_url) )
    assert_equal false, @location.minefield?
    
    # Sanity checks
    [ 'http://pmog.com/codex', 'http://dev.pmog.com', 'http://localhost:3000/forums' ].each do |url|
      @location = Location.find_or_create_by_url( Url.normalise(url) )
      assert_equal false, @location.minefield?
      assert_equal true, @location.protected_by_pmog?
      assert_equal nil, @location.check_for_pmog_profile_page
    end
    
    [ 'www.suttree.com', 'www.google.co.uk', 'http://news.bbc.co.uk/sport/default.stm', 'dopplr.com', 'www.guardian.co.uk/sport' ].each do |url|
      @location = Location.find_or_create_by_url( Url.normalise(url) )
      assert_equal false, @location.minefield?
      assert_equal false, @location.minefield?
      assert_equal false, @location.protected_by_pmog?
      assert_equal nil, @location.check_for_pmog_profile_page
    end
  end
end
