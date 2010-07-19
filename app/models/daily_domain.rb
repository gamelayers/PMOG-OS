# == Schema Information
# Schema version: 20081220201004
#
# Table name: daily_domains
#
#  id          :string(36)    default(""), not null, primary key
#  user_id     :string(36)
#  location_id :string(36)
#  hits        :integer(11)   default(0)
#  week        :integer(2)
#  month       :integer(2)
#  year        :integer(2)
#  created_on  :date
#  updated_on  :date

# The daily_domains table is one of the largest in our database.
# We partition the tables so that each months records are stored within
# a date-stamped table. For example, records for this month (April 2009)
# would be stored in a table called 'daily_domains_04_09'. As a result of
# this, we make sure to call 'set_table_name' from the various callbacks
# to ensure that ActiveRecord is talking to the right table. We also
# override AR::find for the same reason - duncan 11/04/09
class DailyDomain < ActiveRecord::Base
  belongs_to :location
  #belongs_to :old_location
  belongs_to :user

  before_save :set_partition_name, :denormalise_timestamps
  before_create :set_partition_name, :set_timestamps
  before_destroy :set_partition_name

  acts_as_cached

  # get all daily_domain partitions
  def self.get_all_tables
    result = DailyDomain.execute("show tables like 'daily_dom%'")
    all = []
    result.each { |x| all << x.to_s }
    return all
  end

  # Override find so that we can partition the daily_domains table across multiple
  # date-stamped tables, daily_domains_month_year.
  # - this is a simple way of partitioning a large database table
  def self.find(*params)
    set_partition_name
    super
  end

  # Used in callbacks to make sure the table_name is always up-to-date
  def set_partition_name
    DailyDomain.partition_name
  end

  # Used in callbacks to make sure the table_name is always up-to-date
  # - not very dry, as you can see
  def self.set_partition_name
    DailyDomain.partition_name
  end

  # Determines the correct database table name for this model
  def self.partition_name
    #(RAILS_ENV != 'test' || RAILS_ENV != 'development') ? "daily_domains_#{Time.now.strftime('%m_%y')}" : 'daily_domains'
    (RAILS_ENV != 'test' && RAILS_ENV != 'development' && RAILS_ENV != 'staging') ? "daily_domains_#{Time.now.strftime('%m_%y')}" : 'daily_domains'
  end

  # When the model is initialised, we want to make sure it looks in the right place.
  # - the before save/create/destroy callbacks will ensure that the table name
  #   is always up to date, should the month rollover and the table name would
  #   otherwise be cached internally
  set_table_name set_partition_name

  # Copies the current daily_domains table for use in the future
  # - call this method from cron to ensure the daily_domains table
  #   for upcoming months is created ahead of time
  # - if the table already exists, catch the exception and return
  def self.create_partition_table
    current_table_name = 'daily_domains_' + Date.today.strftime('%m_%y')
    next_table_name = 'daily_domains_' + 1.month.from_now.strftime('%m_%y')
    execute( "CREATE TABLE #{next_table_name} LIKE #{current_table_name}" )
  rescue ActiveRecord::StatementInvalid => e
    puts e.message
  end

  # What were the most popular tlds on TheNethernet, yesterday
  def self.top_domains
    raise Exception.new('Slave database configuration not configured') if configurations['slave'].nil?
    connection = self.connection
    establish_connection configurations['slave']
    tlds = find( :all, :select => "count(id) AS total, location_id", :conditions => { :created_on => Date.yesterday }, :group => "location_id", :order => "total DESC", :limit => 20)

    top_tlds = []
    tlds.each do |tld|
      top_tlds << [tld.location.url, tld.total]
    end

    Mailer.deliver_top_domains(
      :subject => "The Nethernet: Top Domains For #{Date.yesterday}",
      :recipients => [ 'exec@gamelayers.com', 'eng@gamelayers.com' ],
      :body => { :top_tlds => top_tlds }
    )
    self.connection = connection
  end

  protected
  # Note the created_on/updated_on nonsense here. For some reason the around_filter for
  # setting timezones doesn't seem to kick in on these daily domains, where it is most
  # valuable. So we set it by hand here, just to make sure that the correct timezones filter through.
  def set_timestamps
    self.id = create_uuid
    self.created_on = TzTime.zone.now.to_date.to_s(:db) rescue Date.today.to_s(:db)
    self.updated_on = TzTime.zone.now.to_date.to_s(:db) rescue Date.today.to_s(:db)
  end

  def denormalise_timestamps
    self.updated_on = TzTime.zone.now.to_date.to_s(:db) rescue Date.today.to_s(:db)
    self.week = TzTime.zone.now.strftime('%W') rescue Date.today.strftime('%W')
    self.month = TzTime.zone.now.strftime('%m') rescue Date.today.strftime('%m')
    self.year = TzTime.zone.now.strftime('%Y') rescue Date.today.strftime('%Y')
  end
end
