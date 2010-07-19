# This environment is used for running production tasks on staging
# It is a duplicate of the production environment with just a few things
# taken out. Note that there must be a cron entry in database.yml that
# duplicates the production connection settings for this to make sense - duncan 29/02/08

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
# config.action_mailer.raise_delivery_errors = false

# Hodel logger is quite verbose, so let's limit that here
# See http://nubyonrails.com/articles/a-hodel-3000-compliant-logger-for-the-rest-of-us
# and http://forum.engineyard.com/forums/6/topics/32
#config.logger.level = Logger::INFO

# Using ERROR logging as our track controller can fill a log file
# in no time. Shame, but we can switch back to INFO if we need to
# for debugging reasons - duncan 29/02/08
#config.logger.level = Logger::ERROR

config.action_mailer.delivery_method = :sendmail