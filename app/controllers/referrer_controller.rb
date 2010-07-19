class ReferrerController < ApplicationController

  # This action is routed to http://<url>/referrer/<login>
  def index
    if session[:user].nil?

      @inviter = User.find_by_login(params[:id])

      new_beta_key = @inviter.beta_keys.create(:emailed => 1)

      cookies[:beta_key] = { :value => new_beta_key.key, :expires => 2.weeks.from_now }
    end
    
    redirect_to "/"
  end

end
