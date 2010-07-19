# Be sure to restart your web server when you modify this file.

IsProduction = ENV['RAILS_ENV'] == 'production'
IsStaging = ENV['RAILS_ENV'] == 'staging'
IsDevelopment = ENV['RAILS_ENV'] == 'development'
IsTest = ENV['RAILS_ENV'] == 'test'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# For attachment_fu, I think
ENV['INLINEDIR'] = "/tmp/ruby/"

# Authorization constants
AUTHORIZATION_MIXIN='object roles'
DEFAULT_REDIRECTION_HASH = { :controller => 'session', :action => 'new' }

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  config.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc

  # Use the hodel 3000 compliant logger so that we can use the rails analyzer tools.
  # Also rotate log files on size rather than time (creates 50 5MB files)
  # See http://nubyonrails.topfunky.com/articles/read/883
  # See http://blog.caboo.se/articles/2005/12/15/who-said-size-is-not-important
  # require 'hodel_3000_compliant_logger'
  # config.logger = Hodel3000CompliantLogger.new(config.log_path)

  # Note that we removed the other parameters from the HodelLogger (50, 5242880) as
  # that results in blank white pages and broken/empty requests...

  # Standard logger
  #config.logger = Logger.new(config.log_path, 50, 1048576)

  # Rotate log files on size rather than time (creates 50 1MB files)
  # See http://blog.caboo.se/articles/2005/12/15/who-said-size-is-not-important
  #config.logger = Logger.new(config.log_path, 50, 1048576)

  # See Rails::Configuration for more options

  # Make sure white_list loads first
  config.plugins = [:white_list, :sanitize_params, :all]

  # Activate observers that should always be running
  config.active_record.observers = :user_observer, :topic_observer

  config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir|
    File.directory?(lib = "#{dir}/lib") ? lib : dir
  end

  # Make ActiveRecord only save the attributes that have changed since the record was loaded.
  config.active_record.partial_updates = true
end

ASSET_IMAGE_PROCESSOR = :image_science || :rmagick || :none

Inflector.inflections do |inflect|
  inflect.irregular 'motd', 'motd'
  inflect.irregular 'shoppe', 'shoppe'
  inflect.irregular 'fave', 'faves'
end

# For Fast Session, via http://code.google.com/p/rails-fast-sessions/
CGI::Session::ActiveRecordStore::FastSessions.fallback_to_old_table = true

DB_STRING_MAX_LENGTH = 255
DB_TEXT_MAX_LENGTH = 40000
HTML_TEXT_FIELD_SIZE = 15

# PMOG specific extensions.
gem 'ruby-openid'
require 'openid'
require 'uuidtools'
require 'ostruct'
require "date_time_ext.rb"
require 'array_extensions'
require 'active_record_extensions'
require 'config/active_record_search.rb'
require 'pmog_extensions'
require 'md5'
require 'forgery_protection_extension'
require 'to_bool'
require 'savepoints.rb'

# This is so we can validate comments
require RAILS_ROOT + '/lib/mixins/validateable.rb'

# This is so we can have uuids for votes
require RAILS_ROOT + '/lib/mixins/voteable.rb'

# This adds a before? and after? method to the Time class
require RAILS_ROOT + '/lib/mixins/before_and_after.rb'

# Partial help files
HELP_FILES = Dir[ RAILS_ROOT + '/app/views/shared/help/_*.html.erb' ].map{ |f| f.gsub!( RAILS_ROOT + "/app/views/", "" )}
HELP_FILES.map{ |f| f.gsub!( "shared/help/_", 'shared/help/' )}
HELP_FILES.map{ |f| f.gsub!( '.html.erb', '' )}

# Partial footer tips files
FOOTER_DIDYOUKNOW = Dir[ RAILS_ROOT + '/app/views/help/footer_tips/_*.html.erb' ].map{ |f| f.gsub!( RAILS_ROOT + "/app/views/", "" )}
FOOTER_DIDYOUKNOW.map{ |f| f.gsub!( "help/footer_tips/_", 'help/footer_tips/' )}
FOOTER_DIDYOUKNOW.map{ |f| f.gsub!( '.html.erb', '' )}

# Partial invitation files
INVITATION_FILES = Dir[ RAILS_ROOT + '/app/views/shared/invitation/_*.html.erb' ].map{ |f| f.gsub!( RAILS_ROOT + "/app/views/", "" )}
INVITATION_FILES.map{ |f| f.gsub!( "shared/invitation/_", 'shared/invitation/' )}
INVITATION_FILES.map{ |f| f.gsub!( '.html.erb', '' )}

# A Rails 2.1 workaround, see http://dev.rubyonrails.org/ticket/11528
require 'tzinfo/timezone_proxy'

## Another Rails 2.1 change, this time to resolve stack level too deep errors
require 'will_paginate'

require 'lib/time_ext.rb'

# Stop the asset cachebuster in production
ENV['RAILS_ASSET_ID'] = '' if Rails.env == 'production'

# For the play button, current deprecated
WEIGHTS_FILE = "#{RAILS_ROOT}/config/play_weights.yml"

# Give the models access to the pmog host
ActiveRecord::Base.module_eval do
  def pmog_host
    case Rails.env
      when 'production' then 'http://thenethernet.com'
      when 'utility' then 'http://thenethernet.com'
      when 'cron' then 'http://thenethernet.com'
      when 'staging' then 'http://dev.thenethernet.com'
      else 'http://0.0.0.0:3000'
    end
  end
end

# This is to facilitate the news blog telling us it has been updated and that we should clear the cache
Pingback.save_callback do |ping|
    puts "Successful Pingback"
    RssReader.clear_cache("home_news_feed")

    ping.reply_ok # report success.
end

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
