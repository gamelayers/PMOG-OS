#require "json"
require "oauth"

# include thise into the user space

module OauthLoginModule
  TWITTER_CHECK_AUTH = 'https://twitter.com/account/verify_credentials.json'
  TWITTER_FRIENDS = 'https://twitter.com/statuses/friends.json'
  TWITTER_MSG = 'https://twitter.com/statuses/update.json'

  def oauth_authorize
    oauth_site, consumer = OauthLoginModule::get_consumer(params[:id])
    redirect_to home_path and return if oauth_site.nil?

    inner_oauth_authorize(oauth_site, consumer)
  end

  def oauth_success
    oauth_site, consumer = OauthLoginModule::get_consumer(params[:id])
    redirect_to home_path and return if oauth_site.nil?

    inner_oauth_success(oauth_site, consumer)
  end

  protected

  # Used throughout the controller.
  def self.get_consumer(oauth_name)
    oauth_name = "#{oauth_name}_#{RAILS_ENV}" if !oauth_name.nil? and !IsProduction # magic to pic dev/staging/test versions of oauth sites

    oauth_site = OauthSite.find(:first, :conditions => ["name = ?", oauth_name.downcase]) if !oauth_name.nil?

    return nil, nil if oauth_site.nil?

    consumer = OAuth::Consumer.new(oauth_site.consumer_key, oauth_site.consumer_secret,
                 :site=> oauth_site.url,
                 :request_token_url => oauth_site.request_url,
                 :access_token_url => oauth_site.access_url,
                 :authorize_url => oauth_site.authorize_url)

    return oauth_site, consumer
  end

  def session_tokens
    puts "OAUTH_REQUEST_TOKEN: #{session[:oauth_request_token]}"
    puts "OAUTH_REQUEST_SECRET: #{session[:oauth_request_secret]}"
  end

  def inner_oauth_authorize(oauth_site, consumer)
    request_token = consumer.get_request_token

    session[:oauth_request_token] = request_token.token
    session[:oauth_request_token_secret] = request_token.secret

    #session_tokens

    # Send to twitter.com to authorize
    redirect_to request_token.authorize_url
    return
  end

  def inner_oauth_success(oauth_site, consumer)

    #session_tokens

    request_token = OAuth::RequestToken.new(consumer, session[:oauth_request_token], session[:oauth_request_token_secret])

    # Exchange the request token for an access token.

    #puts "Getting access token"
    access_token = request_token.get_access_token

    #puts "#{access_token} #{access_token.to_yaml}"

    #response = consumer.request(:get, TWITTER_CHECK_AUTH, access_token,  :scheme => :query_string )
    #response = access_token.get(TWITTER_CHECK_AUTH)

    #puts "#{response} #{response.body}"

    screen_name = access_token.params[:screen_name]
    screen_name = access_token.params['screen_name'] if screen_name.nil?

    #puts "SCREEN_NAME #{screen_name}"

    if false
      case response
        when Net::HTTPSuccess
          user_info = JSON.parse(response.body)
          #puts "******* user_info #{user_info}.to_yaml"

          unless user_info['screen_name']
            flash[:notice] = "Authentication failed"
            redirect_to :action => :index and return
          end
          screen_name = user_info['screen_name']
       end
    end

    # We have an authorized user, save the information to the database.

    remote_login = screen_name

    credentials = OauthCredential.get_credentials(oauth_site, remote_login)

    if !credentials.nil? and !credentials.user.nil? # you already have an account
       session[:user] = credentials.user.id
       credentials.user.remember_me
       cookies[:auth_token] = { :value => credentials.user.remember_token , :expires => credentials.user.remember_token_expires_at }
       redirect_to home_path and return
    end

    password = ""
    10.times { password << "abcdefghijklmnopqrstuvwxyz"[rand(26)] } # fake password

    params['user'] = HashWithIndifferentAccess.new if params['user'].nil?
    params['user']['password'] = password

    def make_name(remote_login)
       extra = ""
       5.times { extra << "01234567890"[rand(10)] }
       return "#{remote_login}#{extra}"
    end

    local_login = remote_login
    tries = 0
    while User.find(:first, :conditions =>["login = ?", local_login]) != nil and tries < 5
      local_login  = make_name(remote_login)
      local_login = local_login[0, User::LOGIN_MAX_LENGTH] # make sure we don't cause errors
      tries = tries + 1 # protect against loops
    end

    params['user']['login'] = local_login
    params['user']['remote_login'] = remote_login
    params['user']['signup_source'] = 'twitter'

    val = create # call our users_controller.create

    #debugger
    # yep, do this afterward, if everything works the user has been redirected away, no need to wait
    if !@user.nil?
      OauthCredential.new_credential(oauth_site, remote_login, access_token, @user)
      # send twitter message
      response2 = access_token.post(TWITTER_MSG, { :status=>"Just started playing on The Nethernet at http://thenethernet.com/join/#{local_login}" } )
    end

    return val
  end
end
