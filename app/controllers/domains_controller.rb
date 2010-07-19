class DomainsController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate
  permit 'site_admin'

  def index
    @page_title = "Searching Domain History on "
  end

  def history
    @page_title = "Daily Domain History Browser for "
    @period = (params[:period].nil? || params[:period].empty?) ? 'today' : params[:period]
    @user = User.find_by_login(params[:id])
    @history = @user.daily_domains.send(@period)
  end

  def search
    url = Url.normalise( URI.parse( Url.normalise( params[:domain] ) ).host )
    domain = 'http://' + Url.domain(url)
    @user = User.find_by_login(params[:login])
    @location = Location.find_or_create_by_url(domain)
    @domain = Location.find_or_create_by_url(domain)

    @start_date = 4.weeks.ago.beginning_of_day.to_time.to_s(:db)
    @end_date = Date.today.end_of_day.to_time.to_s(:db)

    @hits = DailyDomain.find( :all, :conditions => [ 'user_id = ? AND location_id = ? AND DATE(created_on) BETWEEN ? AND ?', @user.id, @domain.id, @start_date, @end_date ], :group => 'DATE(created_on)' )
    @visits = DailyLogIn.find( :all, :conditions => [ 'user_id = ? AND DATE(created_at) BETWEEN ? AND ?', @user.id, @start_date, @end_date ] )
  end
end
