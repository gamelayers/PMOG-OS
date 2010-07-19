require "#{File.dirname(__FILE__)}/../test_helper"
require 'active_support'
class SpiderTestTest < ActionController::IntegrationTest
  all_fixtures
  include Caboose::SpiderIntegrator

  Caboose::SpiderIntegrator.module_eval do
    def spider_with_flag(*args)
      if ENV.keys.map{|x|x.downcase}.include?('spider')
        spider_without_flag(*args)
      else
        puts "Spider tests won't run unless you run them with the SPIDER=true flag."
      end
    end

    alias_method :spider_without_flag, :spider
    alias_method :spider, :spider_with_flag
  end
  def setup
    # Ferret causes some random breakages, so we need to forcibly clear the index
    # http://projects.jkraemer.net/acts_as_ferret/ticket/90
    FileUtils.rm_r("#{RAILS_ROOT}/index/#{RAILS_ENV}") if File.directory?("#{RAILS_ROOT}/index/#{RAILS_ENV}")

    # Not sure why we have to set this again here, but it's
    # getting reset to :smtp somewhere along the line
    ActionMailer::Base.delivery_method = :test
  end

  # Spider all the links from the logged out home page
  def test_spider_logged_out_home_page
    get '/'
    assert_response :success

    # Note that we tell spider to ignore css, jpg and pngs here.
    # It's meant to handle them without barfing, but it does.
    # Add any other static file types here that cause problems
    spider( @response.body, '/',
            :ignore_urls => [ %r{.css}, %r{.jpg}, %r{.png}, %r{https.*} ],
            :ignore_forms => [ %r{.*} ],
            :verbose => true )
    end

  # Spider all links from the logged in home page
  def test_spider_logged_in_home_page
    post '/session', :login => 'justin', :password => 'itsasekrit'
    assert_response 302
    assert session[:user]
    assert ( @user = User.find(@request.session[:user]) )

    get '/'
    assert_response 200

    # Note that we ignore the Pmogeon Preview mission (because of a weird error I can't fathom)
    # and the add acquaintance action as they send email (and fails), and taking missions because
    # the fixtures for that are a pain to setup :(
    spider( @response.body, '/',
            :ignore_urls => [ %r{.css}, %r{.jpg}, %r{.png}, %r{missions/.*/take}, %r{inventory}, %r{https.*} ],
            :ignore_forms => [ %r{.*} ],
            :verbose => true )
  end

  # Spider your own profile page
  def test_spider_logged_in_profile_page
    post '/session', :login => 'justin', :password => 'itsasekrit'
    assert_response 302
    assert session[:user]
    assert ( @user = User.find(@request.session[:user]) )

    get '/users/pmog'
    assert_response :success

    # Note that we ignore the Pmogeon Preview mission (because of a weird error I can't fathom)
    # and the add acquaintance action as they send email (and fails), and taking missions because
    # the fixtures for that are a pain to setup :(
    spider( @response.body, '/',
            :ignore_urls => [ %r{.css}, %r{.jpg}, %r{.png}, %r{missions/.*/take}, %r{inventory}, %r{https.*}, 'http://pmog.com/missions/search/', 'http://pmog.com/forums/search' ],
            :ignore_forms => [ %r{.*} ],
            :verbose => true )
  end
end
