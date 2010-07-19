require 'net/http'
require 'net/https'
require 'rexml/document'

class YahooAuthorizationException < Exception; end

module Yahoo
  module ControllerMethods
    # Calling this method in your desired controller will automatically create a <tt>##login</tt> action in that controller
    # which will redirect the user to Yahoo's authentication page for your registered application.
    #
    # Configure the behavior of the plugin as follows:
    #
    # <tt>:action_name</tt>:: overrides +login+ as the name of the action automatically created in your controller
    # <tt>:params</tt>::      a Hash of parameters like <tt>{:send_userhash => 1, :appdata => 'someFlag'}</tt> sent with your login request
    def authorizes_through_yahoo(options = {})
      options = {:action_name => 'login', :params => {}}.merge(options)
      Yahoo.config['login_url'] = {:controller => self.controller_name, :action => options[:action_name]}
      define_method(options[:action_name]) do
        redirect_to authentication_url(options[:params])
      end
    end
  end
end

ActionController::Base.class_eval do
  extend Yahoo::ControllerMethods
  helper Yahoo::HelperMethods
end