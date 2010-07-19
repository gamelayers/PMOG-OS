module Yahoo
  module HelperMethods
    # Generates the url required by Yahoo BBAuth to allow a user to log in to your app
    def auth_url
      url_for Yahoo.config['login_url']
    end
  end
end