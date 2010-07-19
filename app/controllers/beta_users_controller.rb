class BetaUsersController < ApplicationController
  before_filter :login_required, :except => [ :create ]
  #before_filter :authenticate, :only => :index
  permit 'site_admin', :except => :create

  # GET /beta_users
  def index
  	@page_title = 'Beta Users of '
  	@invited_beta_users = BetaUser.count_invited
  	@signed_up_beta_users = BetaUser.count_signed_up
    @beta_users = BetaUser.paginate(  :all,
                                      :order => 'beta_users.created_at DESC',
                                      :page => params[:page],
                                      :per_page => 25 )

    respond_to do |format|
      format.html # index.rhtml
    end
  end

  def search
    query = '%' + params[:q] + '%'
    @beta_users = BetaUser.find( :all, :conditions => [ 'email LIKE ?', query ], :limit => 10 )
  	@page_title = 'Admin : Search Beta Users of '
    
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # POST /beta_users
  def create
    @beta_user = BetaUser.new(params[:beta_user])

    if @beta_user.save
      render :partial => 'success'
    else
      render :partial => 'fail'
    end
  end

  # DELETE /beta_users/1
  # DELETE /beta_users/1.xml
  def destroy
    @beta_user = BetaUser.find(params[:id])
    @beta_user.destroy

    respond_to do |format|
      format.html { redirect_to beta_users_url }
    end
  end

  def admin_create
    @beta_user = BetaUser.new(params[:beta_user])

    if @beta_user.save
      flash[:notice] = 'Beta user added'
    else
      flash[:notice] = 'Failed to add beta user'
    end
    redirect_to :action => :index
  end
  
  def send_invite
    sender = User.caches( :find_by_email, :with => 'self@pmog.com' )
    @beta_user = BetaUser.find(params[:id])
    if @beta_user.email_beta_key(sender, {:recipient => @beta_user.email})
      flash[:notice] = 'Beta invite sent'
    else
      flash[:notice] = 'Failed to send beta email'
    end

    redirect_to :action => :index, :page => params[:page]
  end
  
  def resend_invite
    sender = User.caches( :find_by_email, :with => 'self@pmog.com' )
    @beta_user = BetaUser.find(params[:id])
    if @beta_user.email_beta_key_again(sender)
        flash[:notice] = 'Beta invite re-sent'
      else
        flash[:notice] = 'Failed to re-send beta email'
      end

    redirect_to :action => :index, :page => params[:page]
  end
end
