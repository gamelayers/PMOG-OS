module DailyDomainsExtension
  # Return a hash of location_id => hits for +period+
  def hits(period)
    get_cache("#{proxy_owner.id}_hits_#{period}") do
      hits_for(period.to_s)
    end
  end

  # Returns all domains
  def today
    find( :all, :conditions => [ 'created_on = ?', Date.today.to_s(:db) ], :order => 'created_on ASC' )
  end
  
  def yesterday
    find( :all, :conditions => [ 'created_on = ?', Date.yesterday.to_s(:db) ], :order => 'created_on ASC' )
  end

  def this_week
    find( :all, :conditions => [ 'year = ? AND week = ?', Date.today.strftime('%Y'), Date.today.strftime('%W') ], :order => 'created_on ASC' )
  end
  
  def last_week
    find( :all, :conditions => [ 'year = ? AND week = ?', 1.week.ago.strftime('%Y'), 1.week.ago.strftime('%W') ], :order => 'created_on ASC' )
  end

  # Have the user visited the TLD for +location+ in the last +steps_back+ hits?
  def recently_visited?(location, steps_back = 10)
    domain_url = 'http://' + Url.caches( :domain, :with => location.url )
    domain = Location.caches( :find_or_create_by_url, :with => domain_url )
    return false unless domain

    latest_tlds = find( :all, :conditions => {:location_id => domain.id}, :order => 'created_on DESC, hits DESC', :limit => steps_back )
    latest_tlds.empty? ? false : true
  end

  # If the user has visited this +location+ today, just increment their hits
  # If they've not visited it before, create a new record. Note that his is commonly called
  # from the track controller, for rewarding users with +datapoints+ for each unique daily +domain+
  # Note that we don't flush the cache of today, when updating hits
  # but neither do we use it outside of the badges. Note that we explicitly set the date using
  # +TzTime+ rather than +Date+, since it is important to players that the daily visits
  # they make to websites counting towards badges are registered in the correct timezone
  def unique(location)
    date = TzTime.zone.now.to_date.to_s(:db) rescue Date.today.to_s(:db)
    domain = previous_visit(location, date)

    # If it's the first hit to a domain today, run a badge check.
    # Do the same for every 4th hit to a domain, too
    if domain.nil?
      create( :location_id => location.id, :hits => 1 )
      proxy_owner.expire_cache("#{location}_#{date}")
    else
      domain.hits += 1 # update the hits today
      domain.save
    end

    # Note that we only run a badge check on the first and every fifth hit to a tld
    # - disabled for performance - duncan 28/01/09
    #Badge.check(proxy_owner, location) if domain.nil? or domain.hits % 5 == 0

    return (domain.nil? ? true : false)
  end
  
  def count_daily
    proxy_reflection.klass.count(
      :conditions => ['user_id = ? and created_on > ?', proxy_owner.id, 24.hours.ago])
  end
  
  protected
  def previous_visit(location, date)
    proxy_owner.get_cache("#{location}_#{date}", :ttl => 1.day) do
      find( :first, :conditions => [ 'location_id = ? AND created_on = ?', location.id, date ] )
    end
  end

  def hits_for(period)
    case period
      when 'today' then conditions = { :created_on => Date.today.to_s(:db) }
      when 'yesterday' then conditions = { :created_on => Date.yesterday.to_s(:db) }
      when 'this_week' then conditions = { :year => Date.today.strftime('%Y'), :week => Date.today.strftime('%W') }
      when 'last_week' then conditions = { :year => 1.week.ago.strftime('%Y'), :week => 1.week.ago.strftime('%W') }
      when 'all_time' then conditions = {} 
    else
     return {}
    end

    domains = {}
    find(:all, :select => 'location_id, sum(hits) as hits', :conditions => conditions, :group => 'location_id').each do |d|
      domains[d.location_id] = d.hits
    end
    domains
  end
end
