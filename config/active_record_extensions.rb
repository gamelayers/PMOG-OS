class ActiveRecord::Base
  # Include the overlay helpers, which gives us access to
  # falls_below_quality_threshold and falls_outside_nsfw_threshold
  # from within the models
  extend OverlaySystem

  # Simple UUID helper, mainly for non-sequential primary ids
  def create_uuid
    # In future, we should use UUID.timestamp_create.to_i
    # since that is a 16 byte char, rather than a 36 char one.
    UUID.timestamp_create().to_s
  end

  # This is a class method as we'll want to display an overview of mines
  # in the browser, rather than an alert per mine which would be most annoying.
  # Note that we return a new UUID so that the browser knows which overlay is
  # sending it messages, should the user trigger any actions from within it.
  #
  # Note :id is not set here and instead needs to be set using the opts hash.
  # with the window_id from the partial that :body yields to.
  def self.to_hash(opts = {})
    return { :type => self.name,
             :subject => '',
             :body => yield }.merge(opts)
  end

  # Uses +create_permalink+ to create a unique url
  # name for this model/instance
  def create_unique_permalink(text, column = 'url_name' )
    permalink = create_permalink(text)
    while count( :all, :conditions => { column.to_sym => permalink } ) > 0
      permalink += '_'
    end
    permalink
  end

  # Create a permalink out of text, for use in urls
  # From http://textsnippets.com/posts/show/485
  def create_permalink(text)
    t = Iconv.new('ASCII//TRANSLIT', 'utf-8').iconv(text)
    t = t.downcase.strip.gsub(/[^-_\s[:alnum:]]/, '').squeeze(' ').tr(' ', '-')
    (t.blank?) ? '-' : t
  end

  # Useful memcached versioning helper.
  # From http://pastie.caboo.se/65956
  def version
    attributes.has_key?('updated_at') ? updated_at.to_i : attributes.values.join(":")
  end

  # Restricted attributes and included associations for JSON and XML output
  cattr_accessor :default_private_api_fields, :private_api_fields, :included_api_associations

  # We never want to give his information away
  @@default_private_api_fields = [ :password, :password_confirmation, :crypted_password, :remember_token, :remember_token_expires_at, :salt, :email, :created_on, :created_at, :updated_on, :updated_at ]

  # Returns JSON description of a model, taking note of private_api_fields and included_api_associations
  # def to_json(options = {})
  #   @@private_api_fields = ((@@default_private_api_fields || []) + (@@private_api_fields || [])).uniq
  #   options = { :except => @@private_api_fields, :include => @@included_api_associations }.merge(options)
  #   super( :except => options[:except], :include => options[:include] )
  # end

  # Returns XML description of a model, taking note of only the private_api_fields
  def to_xml(options = {})
    @@private_api_fields = (@@default_private_api_fields + @@private_api_fields).uniq
    options = { :except => @@private_api_fields, :include => @@included_api_associations }.merge(options)
    super( :except => options[:except] )
  end

  # Get the name of the calling method
  # From http://snippets.dzone.com/posts/show/2787
  def caller_method_details
    parse_caller(caller(2).first)
  end

  def parse_caller(at)
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
      file = Regexp.last_match[1]
      line = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      [file, line, method]
    end
  end

  # Faked database cursor
  # See http://pmade.com/svn/oss/all_records/trunk/lib/all_records.rb
  #
  # Usage:
  #  User.all {|u| ... }
  #  User.all(50) {|u| ... }
  #  User.all(:conditions => ['created_at >= ?', Time.now - 48.hours]) {|u| ... }
  def self.all (*args, &block)
    options = args.last.is_a?(Hash) ? args.pop : {}
    count   = args.first || 25
    start   = 0

    # force records to be returned in a stable order
    options.update(:order => :id, :limit => count)

    loop do
      records = find(:all, options.merge(:offset => start))
      records.each(&block)
      break if records.size < count
      start += count
    end
  end

  # Query the replicated database and reset the connection to the master
  # - returns the result of the block and resets the connection back to Rails.env
  # - uses the Rails.env entry in database.yml if a slave entry is not configured
  def self.slave_setup
    replica = (configurations['slave'].nil? ? Rails.env : 'slave')
    establish_connection configurations[replica]
    result = yield
    establish_connection Rails.env
    result
  end

  private
  # Time saver
  def self.execute( sql )
    ActiveRecord::Base.connection().execute( sql )
  end
end
