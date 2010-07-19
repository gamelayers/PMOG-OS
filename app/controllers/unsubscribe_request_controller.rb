class UnsubscribeRequestController < ApplicationController
  
  def index
    unless current_user.nil?
      @page_title = "Unsubscribe the email of "
      @user = current_user
    end
    
    if params[:req_id] != nil
      redirect_to :action => 'confirm', :req_id => params[:req_id]
    end
  end
  
  # This is where CM bounces unsubscribe requests to, so that a user can be unsubscribed
  # from their database and from ours. Note that we toggle the Periodic Updates preference
  # to signify which users don't want these emails anymore. Note also that this url must be
  # set in the preferences of *each* subscriber list on CM
  def campaign_monitor
    @user = User.find(:first, :conditions => {:email => params[:emailaddress]})

    if @user
      unsubscribe_request = UnsubscribeRequest.new(:user_id => @user.id)
      unsubscribe_request.confirmed = true
      unsubscribe_request.save
    
      @user.preferences.set Preference.preferences[:periodic_updates][:text], false
    
      flash[:notice] = 'You have been successfully unsubscribed'
      session[:unsubscribed] = true
    else
      session[:unsubscribed] = false
      flash[:notice] = 'Failed to unsubscribe ' + params[:emailaddress]
    end
    redirect_to :action => 'complete'
  end

  def complete
    @unsubscribed = session[:unsubscribed]
  end
  
  def new_request
    if params[:user_id].nil? && params[:user][:email].empty?
      redirect_to :action => 'index'
    elsif params[:user_id]
      @user = User.find_by_id(params[:user_id])
    elsif params[:user][:email]
      @user = User.find_by_email(params[:user][:email])
    end
    unsubscribe_request = UnsubscribeRequest.new(:user_id => @user.id)
    unsubscribe_request.save

    Mailer.deliver_confirm_unsubscribe(
      :subject => "[The Nethernet] Unsubscribe Request Confirmation",
      :recipients => @user.email,
      :body => { :user => @user, :unsubscribe_request => unsubscribe_request, :controller => "unsubscribe_request" }
    )
  end
  
  def confirm
    if params[:req_id].empty?
      redirect_to :action => 'index'
    else
      unsubscribe_request = UnsubscribeRequest.find_by_id(params[:req_id])
      unsubscribe_request.confirmed = true
      unsubscribe_request.save
      
      @user = User.find_by_id(unsubscribe_request.user_id)
      
      @user.preferences.set Preference.preferences[:new_acquaintance][:text], false
      
    end
  end

end
