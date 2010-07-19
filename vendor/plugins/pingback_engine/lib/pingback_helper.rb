module PingbackHelper
  
  # Call this in the before_filter or any controller action to let scanning blogs know
  # you're ping-able. The xml-rpc server is propagated using the <tt>X-Pingback </tt>
  # HTTP header.
  #
  # See http://hixie.ch/specs/pingback/pingback#header
  #
  # Example:
  #
  # 
  def set_xpingback_header
    response.headers["X-Pingback"] = pingback_server_url
  end
  
  # Use this in your layout or view to propagate the xml-rpc server url using the 
  # pingback meta tag.
  #
  # ...
  def pingback_link_tag
    '<link rel="pingback" href="'+pingback_server_url+'" />'
  end
  
  
  def pingback_server_url
    url_for(:controller => :pingback, 
      :action => :xml, :only_path => false)
  end
end
