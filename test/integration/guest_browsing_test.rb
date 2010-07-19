require File.dirname(__FILE__) + '/../test_helper'

class GuestBrowsingTest < ActionController::IntegrationTest
  all_fixtures

  def setup
    # Ferret causes some random breakages, so we need to forcibly clear the index
    # http://projects.jkraemer.net/acts_as_ferret/ticket/90
    FileUtils.rm_r("#{RAILS_ROOT}/index/#{RAILS_ENV}") if File.directory?("#{RAILS_ROOT}/index/#{RAILS_ENV}")
  end

  def test_cannot_browse_as_guest
    unbrowseable_urls = %w(
      /privacy
      /users/suttree/edit
      /admin
      /tools/
      /portals
      /mines
      /crates
      /jobs/list
      /users/marc/messages
      /admin/inventory/suttree
      /missions/mission_with_long_text/edit
      /acquaintances/add/justin?type=ally
      /acquaintances/remove/suttree?type=rival
    )

    unbrowseable_urls.each do |url|
      get url
      begin
        assert_response 302, "browsing url: #{url}"
      rescue => e
        raise $!
      end
    end
  end

  def old_stuff_gets_forwarded
    browsable_urls = %w(
      /help/toolbar
      /help/install
    )
    unbrowseable_urls.each do |url|
      get url
      begin
        assert_response 301, "browsing url: #{url}"
      rescue => e
        raise $!
      end
    end
  end

  def test_can_browse_as_guest
    browseable_urls = %w(
      /
      /users
      /guide
      /about/sightseeing
      /openid/new
      /users/suttree
      /guide/support/toolbar
      /guide/support/install
      /events
      /missions
      /missions/mission_with_long_text
      /missions/mission_with_long_text?user_page=2
    )

    browseable_urls.each do |url|
      get url
      begin
        assert_response :success, "browsing url: #{url}"
      rescue => e
        raise $!
      end
    end
  end
end
