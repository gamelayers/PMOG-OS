# Controller for handling beta sign ups
class BetaController < ApplicationController
  def signup
    logout if logged_in?
    key = BetaKey.find_by_key(params[:id], :conditions => 'emailed = 1')
    render :action => 'key_already_used' and return if key.nil?
    cookies[:beta_key] = { :value => key.key, :expires => 2.weeks.from_now }
    @user = User.new( :email => params[:email] )
  end
  
  protected
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
  end
end