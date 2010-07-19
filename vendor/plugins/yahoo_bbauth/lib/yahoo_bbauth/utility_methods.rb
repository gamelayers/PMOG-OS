require 'md5'

module Yahoo
  # Generates a signature which must be appended to BBAuth requests
  def generate_signature(action, params)
    MD5.hexdigest(Actions[action.to_sym] + params + secret)
  end
  
  # Generates the url--including the signature--for Yahoo BBAuth needed to retrieve the token for a user
  def authentication_url(params = {})
    timestamp = Time.now.to_i
    params.merge!(:appid => application_id, :ts => timestamp)
    http_get_params = params.to_http_get_params
    sig = generate_signature(:authorize, http_get_params)
    uri = AuthHost + Actions[:authorize] + http_get_params + "&sig=#{sig}"
  end
  
  # Generates the url--including the signature--for Yahoo BBAuth needed to retrieve the credentials (wssid and cookie)
  # to make an authenticated request to a Yahoo web service
  def token_request_url(token)
    timestamp = Time.now.to_i
    params = {:appid => application_id, :ts => timestamp, :token => token}
    http_get_params = params.to_http_get_params
    sig = generate_signature(:get_credentials, http_get_params)
    uri = AuthHost + Actions[:get_credentials] + http_get_params + "&sig=#{sig}"
  end
  
  # Call this method inside the action where you verify your user's login.
  # 
  # Returns a Hash containing <tt>:auth_cookie</tt> and <tt>:wssid</tt>, allowing you to make authenticated
  # calls to Yahoo's web services.
  # 
  # <tt>:timeout</tt> is also provided to allow seamless request of new credentials when they have expired.
  def request_yahoo_credentials(token)
    uri = URI.parse(token_request_url(token))
    logger.info "host = " + uri.host
    http = Net::HTTP.new(uri.host, Net::HTTP.https_default_port)
    http.use_ssl = true
    logger.info "token_request_url = " + token_request_url(token)
    resp = http.get(uri.request_uri, nil)
    doc = REXML::Document.new(resp.body).root
    raise YahooAuthorizationException.new("Yahoo BBAuth error: %s %s" % 
      [ doc.elements['//Error/ErrorCode'].text.strip,
        doc.elements['//Error/ErrorDescription'].text.strip ]) unless doc.elements['//Success']
      
    return  { :auth_cookie => doc.elements["//Success/Cookie"].text.strip, 
              :wssid => doc.elements["//Success/WSSID"].text.strip,
              :timeout => doc.elements["//Success/Timeout"].text.strip }
  end
end

class Hash
  # Returns a uri-encoded string suitable for HTTP get requests to Yahoo's BBAuth service
  def to_http_get_params
    URI.encode(self.to_a.sort { |l, r| l.first.to_s <=> r.first.to_s }.map { |key, value| "#{key}=#{value}" }.join('&'))
    #TODO: add recursive serialization for more complex parameters (e.g. { :user => {:name => 'name', :age => 32} })??
  end
end
