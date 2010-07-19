class SuspectsController < ApplicationController
  before_filter :login_required
  #before_filter :authenticate
  permit 'site_admin'
  
  def index
  	@page_title = "Suspect Players of "
    @suspects = Suspect.paginate( :all,
                                  :order => "suspects.timestamp DESC",
                                  :page => params[:page],
                                  :per_page => 100 )
  end
  
  def highrollers
    thresh = params[:threshold] || 8000
    
    @rollers = []
    suspects = Suspect.find :all, :limit => 100 # for now
    for suspect in suspects
      @rollers << suspect if suspect.user.daily_domains.count >= thresh
    end
  end
end
