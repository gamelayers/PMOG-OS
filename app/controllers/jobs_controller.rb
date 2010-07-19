class JobsController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate
  permit 'site_admin'

  def index
    redirect_to :action => 'list'
  end

  def list
    @page_title = 'The Background Job Queue on '
    @jobs = Bj.table.job.paginate( :all,
                                   :order => 'state DESC, priority DESC',
                                   :conditions => "state in ('pending', 'running')",
                                   :page => params[:page],
                                   :per_page => 100 )
  end
end
