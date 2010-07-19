require 'yahoo_bbauth/helper_methods'
require 'yahoo_bbauth/controller_methods'
require 'yahoo_bbauth/utility_methods'
require 'yahoo_bbauth/constants'

module Yahoo
  
  def self.init(config_file = 'yahoo.yml')
    @@config = YAML::load_file("#{RAILS_ROOT}/config/#{config_file}")
  end
  
  # Returns the shared secret generated when registering your application
  def secret
    Yahoo.config['secret']
  end
  
  def application_id
    Yahoo.config['application_id']
  end
  
  # Returns the url within your application that automatically redirects the user to the Yahoo login page for your application
  def login_url
    Yahoo.config['login_url']
  end
  
  protected
  def self.config
    @@config
  end
end

ActionController::Base.class_eval do
  include Yahoo
end