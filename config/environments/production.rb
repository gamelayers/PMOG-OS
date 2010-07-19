# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :smtp

# ActiveRecord for sessions using fast_sessions
#config.action_controller.session_store = :active_record_store

# Memcache for sessions
# Note that you will also need to edit memcached.yml
config.action_controller.session_store = :mem_cache_store

# See http://trac.poocs.net/plugins/browser/trunk/distributed_assets/
host = `uname -n`.strip
config.action_controller.asset_host = %w(
  http://thenethernet.com
)

config.after_initialize do
  require 'application' unless Object.const_defined?(:ApplicationController)
  LoggedExceptionsController.class_eval do
    # Set up the basic authentication system so that we can control access to /logged_exceptions
    include AuthenticatedSystem
    session :session_key => 'thenethernet_session_id'
    before_filter :login_required
    permit 'site_admin'
  end
end

# Hodel logger is quite verbose, so let's limit that here
# See http://nubyonrails.com/articles/a-hodel-3000-compliant-logger-for-the-rest-of-us
# and http://forum.engineyard.com/forums/6/topics/32
# config.logger.level = Logger::INFO

# Using ERROR logging as our track controller can fill a log file
# in no time. Shame, but we can switch back to INFO if we need to
# for debugging reasons - duncan 29/02/08
#config.logger.level = Logger::ERROR

# Should be the default in Rails 2.0
config.action_view.cache_template_loading = true

# So that we can re-use sessions on ext.pmog.com, api.pmog.com, etc...
# See http://blog.vixiom.com/2006/10/24/ensure-that-rails-sessions-remain-valid-over-subdomains-and-https/
ActionController::Base.session_options[:session_domain] = '.thenethernet.com'
