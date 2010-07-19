# Helper model for dealing with urls
# Investigate this for more ideas - http://svn.ruby-lang.org/cgi-bin/viewvc.cgi/trunk/lib/uri/common.rb?view=markup
# Investigate this lib/opedid/util.rb and lib/openid/urinorm.rb for more ideas
class Url
  acts_as_cached

  # A limited sest of subdomains, so that uk.gizmodo.com can be treated the same as gizmodo.com,
  # for fuzzy matching porpoises. Enabled in variant_matches with the promiscuous_matching flag
  # Also, a limited set of tld matches that are interchangeable, so that google.com and 
  # google.co.uk can be treated as the same destination, if promiscuous.
  @@promiscuous_subdomain_matches = [ 'uk', 'en' ]
  @@promiscuous_tld_matches = [ '.co.uk', '.ca', '.ie', '.com', '.us' ]
  # Perhaps use http://cheat.errtheblog.com/s/tld/

  # This will be the one place where we define what is a valid or invalid url.
  def self.valid?(url)
    url = self.normalise(url.to_s)
    return false if url.match( /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ )
    return false unless url.match( /(http|ftp)+(s)?:(\/\/)((\w|\.)+)(\/)?(\S+)?/i )
    return false unless url.match( /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix )
    return true
  end

  # Boolean - is this url an image or swf?
  # Uses URI to split the url and give us just the path,
  # query strings and fragments shouldn't affect this
  def self.unsupported_format?(url)
    url.match( /^file:\/\//ix ) ? true : false
  end

  # Normalises the url (make sure http:// is present as the URI library likes that)
  # Returns +false+ if the url is an IP address or an https address, or empty.
  # Also runs a check using URI.parse
  def self.normalise(url)
    return false if ! url
    return false if url.nil?
    return false if url.empty?
    return false if url =~ /^https:\/\//
    return false if url.match( /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ )

    url.strip!
    unless url =~ /^http:\/\//
      url = 'http://' + url
    end

    url.chop! if url.last == '/'
    url.downcase
    url.gsub!( / /, '%20' )
    url
  end

  # Called by the track controller. Munges the full query string into a url. Note that we
  # can't just use params[:url] as Rails will split up any of those urls if they 
  # contain an ampersand(&). So we just parse the params and get the full url instead.
  # Note that this expects a query string formatted something like this:
  # version=0.6.0&url=http://www.suttree.com
  # with the version and the start and the url further along.
  def self.extract_and_normalise_from_env(url, version)
    return false if url.nil? or url.empty?
    
    url.gsub!( /version=[0-9.]{5,7}/, '' )
    url.gsub!( /&host=.*$/, '' )
    
    # Backwards compatability is always a good thing
    if version.to_f <= "0.416".to_f
      url.gsub!( /&authtoken=.*$/, '' )
      url.gsub!( /&authenticity_token=.*$/, '' )
    else
      url.gsub!( /&auth_token=[a-zA-Z0-9]+/, '' )
      url.gsub!( /&authenticity_token=[a-zA-Z0-9]+/, '' )
    end
    
    # Old versions ping us with ?url=foo whereas new versions ping us
    # with ?version=123&url=bar so handle both here in two simple regexs
    url.gsub!( /^url=/, '' )
    url.gsub!( /^&url=/, '' )
    
    self.normalise(url)
  end

  # Returns only the host. That is, given a url of http://news.bbc.co.uk/path/to/file
  # it will return 'news.bbc.co.uk'. The corroloary to this is Url.domain which would
  # return just 'bbc.co.uk' when given the same url.
  def self.host(url)
    url = self.normalise(url)
    url ? URI.parse( URI.escape(url) ).host.to_s : false
  end

  # Extract the +domain+ from +url+
  # Code modified from the php example on http://answers.google.com/answers/threadview?id=485160
  # Works in memcached using: Url.caches( :domain, :with => url )
  # Useful for unique daily domain checking from the track controller
  def self.domain(url)
    # Check generic validity of the url
    url = self.normalise(url.to_s)
    return false unless url
    return false if url.match( /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ )
    match = url.match( /(http|ftp)+(s)?:(\/\/)((\w|\.)+)(\/)?(\S+)?/i )

    url_array, url_fragments = self._parse(url)
    
    unless url_array.nil?
      domain = url_array[ url_fragments .. url_array.size ].join( '.' )
      return domain
    end
    nil
  end

  # Given a +domain+, returns the top level domain, e.g .com or .co.uk
  def self.tld(domain)
    return false if domain =~ /^http/
    domain.split('.')[1..-1].join('.')
  end

  # Returns the +sub_domain+ from +url+, or nil
  def self.sub_domain(url)
    # Check generic validity of the url
    url = self.normalise(url.to_s)
    return if url.match( /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ )
    match = url.match( /(http|ftp)+(s)?:(\/\/)((\w|\.)+)(\/)?(\S+)?/i )

    url_array, url_fragments = self._parse(url)
    
    unless url_array.nil?
      sub_domain = url_array[0] if url_fragments > 0
      return sub_domain
    end
    nil
  end

  # Lists the variants of a url, to cope with http://suttree.com
  # and http://www.suttree.com representing the same thing. Also
  # if +promiscuous_matching+ is enabled, suttree.com and 
  # suttree.co.uk will also match
  def self.variants(url, promiscuous_matching = false)
    url = self.normalise(url)
    return [] unless url
    
    domain = self.domain(url)
    return [] unless domain

    sub_domain = self.sub_domain(url)
    path = URI.parse(url).path

    # Currently we just return a version with, and a version without the leading www
    # along with the original url and a stripped bare url
    variants = []
    variants << url
    variants << 'http://' + domain + path if sub_domain.nil? or sub_domain =~ /^www*/
    variants << 'http://www.' + domain + path if sub_domain.nil? or sub_domain =~ /^www*/

    # Throw in some extra matches, if requested
    if promiscuous_matching
      @@promiscuous_subdomain_matches.each do |match|
        variants << 'http://' + match + '.' + domain + path
      end
      variants << 'http://' + domain + path if @@promiscuous_subdomain_matches.include? sub_domain
      @@promiscuous_tld_matches.each do |match|
        variants << 'http://' + domain.split('.').first + match + path
        variants << 'http://www.' + domain.split('.').first + match + path
      end

    end

    variants.uniq
  end

  # Used to discover whether +url+ matches +url_to_match+, or indeed
  # whether any variant of +url+ matches +url_to_match+ if required.
  # Bear in mind that 'matches' means 'is pretty much the same as'. For example,
  # pmog.com/users/suttree matches www.pmog.com/users/suttree but dev.pmog.com/users/suttree
  # doesn *not* match pmog.com/users/suttree, or even www.pmog.com/users/suttree.
  # We apply some fuzzy matching to www sub-domains, so that www12 or www-5 are treated
  # equally to the standard www. Some more examples follow:
  #
  # These three urls are the same:
  # flickr.com/photos/suttree1975
  # www.flickr.com/photos/suttree1975
  # www2.flickr.com/photos/suttre1975
  #
  # The first two urls are the same, the third is different:
  # pmog.com/users/suttree
  # www.pmog.com/users/suttree
  # dev.pmog.com/users/suttree
  # 
  # And now we match abc.facebook.com with xyz.facebook.com too
  #
  # If promiscuous_matching is enabled, then we also match the tlds
  # specified in +promiscuous_tld_matches+ so that google.com 
  # matches google.co.uk
  def self.variant_matches(url, url_to_match, promiscuous_matching = false)
    url = self.normalise(url.to_s)
    url_to_match = self.normalise(url_to_match.to_s)
    domain = self.domain(url)
    domain_to_match = self.domain(url_to_match)
    sub_domain_to_match = self.sub_domain(url_to_match)
    path = url.split(domain)[1] rescue nil
    path_to_match = url_to_match.split(domain_to_match)[1] rescue nil

    return url if url == url_to_match
    return false if domain != domain_to_match and ! promiscuous_matching

    url_list = self.variants(url, promiscuous_matching)

    url_list.collect{ |u|
      sub_domain = Url.sub_domain(u)
      
      # pmog.com and www.pmog.com
      return u if sub_domain.nil? and sub_domain_to_match =~ /^www*/ and domain == domain_to_match and path == path_to_match

      # www.pmog.com and pmog.com
      return u if sub_domain =~ /^www*/ and sub_domain_to_match.nil? and domain == domain_to_match and path == path_to_match

      # We only want to do the following for missions, most likely.
      # We'll keep mines, portals and crates the least promiscuous for now.
      if promiscuous_matching
        # uk.pmog.com/en.pmog.com and pmog.com, note that this is strictly only for domains,
        # permalinks or explicit urls won't get matched by this, so uk.pmog.com/foo/bar
        # will not match www.pmog.com/foo/bar. Note that at this stage we know the domains
        # match, so we just need to check the subdomain and path.
        return u if @@promiscuous_subdomain_matches.include? sub_domain and sub_domain_to_match !~ /^www*/ and domain == domain_to_match and path.nil? and path_to_match.nil?
        
        # Facebook and youtube, damn you!
        # Match school.facebook.com with other_school.facebook.com
        # same goes with youtube.com too
        return u if domain == 'facebook.com' and path == path_to_match
        return u if domain == 'youtube.com' and path == path_to_match
        
        # Google.co.uk is the same as Google.com, but
        # google.co.uk/foo/bar is not the same as google.com/foo/bar
        return u if u == url_to_match and path.nil? and path_to_match.nil?
      else
        # Since we're not promiscuous, let's be frigid! Get out this loop as quickly as possible
        # by returning from any matches that fail...

        # dev.pmog.com and www.pmog.com
        return false if sub_domain !~ /^www*/ and sub_domain_to_match =~ /^www*/  and path == path_to_match

        # www.pmog.com and dev.pmog.com
        return false if sub_domain =~ /^www*/ and sub_domain_to_match !~ /^www*/  and path == path_to_match
      end
    }.any?
  end

  # Return the first matching +url+ found in +urls_to_match+, or nil
  def self.first_match(url, urls_to_match, promiscuous_matching = false)
    if (index = urls_to_match.index url)
      return urls_to_match[index]
    else
      matches = []
      url_variants = self.variants(url, promiscuous_matching)
      urls_to_match.each_with_index do |u, index|
        match = url_variants.collect{ |url| u.index url }.compact.first
        return urls_to_match[index] unless match.nil?
      end
    end
    nil
  end

  protected
  # Used by Url.domain and Url.sub_domain to break up a url and
  # figure what we're dealing with
  def self._parse(url)
    # Check generic validity of the url
    return if url.match( /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ )

    url_count = url_count1 = nil
    match = url.match( /(http|ftp)+(s)?:(\/\/)((\w|\.)+)(\/)?(\S+)?/i )
    unless match.nil?
      # Munge the url a wee bit more
      url = match[0]

      url.gsub!( /((http(s)?|ftp):\/\/)/, '' )
      url.gsub!( /([^\/]+)(.*)/, "\\1" )

      # Re-enable this for stricter url parsing
      #url = URI.parse(url).host

      # Figure out how many sections there are to the url we're dealing with
      # Apologies for the crappy variable names, I copied them start from the PHP example :(
      url_count = url.split( '.' )
      url_count1 = url_count.size
      url_count1 -= 1

      # Special case for .co.abc domains
      m = url.match( /\.co\./ )
      unless m.nil?
        url_count1 -= 1
      end

      # Now decrement the counter one last time
      url_count1 -= 1
    end
    return [ url_count, url_count1 ]
  end

  # A test method, which should NOT be used anywhere in the game.
  # There two regexs are reasonably good at parsing urls, however, there is no one
  # regex that works on RFC compliant urls, that is sane and easy to read.
  # However, we should thinkg about using a Bayesian parser, eventually, 
  # and feed it with a bunch of urls from the track controller. It can then
  # act in conjunction with Memcached to give us a much better Url parser than
  # the standard URI library, and have it return us with normalised urls, domains
  # variants and so on. We should then write a big test harness around the code
  # and open source it for great justice
  def self.regex(url = 'http://www.suttree.com' )
    matches = url.match( /^(http|https):\/\/[a-z0-9]+[\-\.]{1}([a-z0-9]+)*(\.)([a-z]{2,5})(([0-9]{1,5})?\/.*)?$/ix )
    return (matches[2] + matches[3] + matches[4]) unless matches.nil?
    
    matches = url.match( /(^(http|https):\/\/[a-z0-9]+(([-.]{1}[a-z0-9]*)+.[a-z]{2,5})(([0-9]{1,5})?\/.*)?$)/ix )
    return (matches[3][1, matches[3].size]) unless matches.nil?

    # Other regexes of note:
    #
    # /(^(http|https):\/\/([a-z0-9]+)(([-.]{1}[a-z0-9]*)+.[a-z]{2,5})(([0-9]{1,5})?\/.*)?$)/ix
    #
    # /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
    #
    #
    # And *the* url regex, good luck getting it to compile though :(
    # http://internet.ls-la.net/folklore/url-regexpr.html  # it burns! argh....
  end
end
