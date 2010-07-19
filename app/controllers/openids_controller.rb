class OpenidsController < ApplicationController
  def show
    redirect_to :action => :new
  end

  def create
    openid_url = params[:openid_url]
    response = openid_consumer.begin openid_url

    if response.status == OpenID::SUCCESS
      redirect_url = response.redirect_url(complete_openid_url, complete_openid_url)
      redirect_to redirect_url
      return
    end

    flash[:error] = "Couldn't find an OpenID for that URL"
    render :action => :new
  end

  def complete
    response = openid_consumer.complete params

    if response.status == OpenID::SUCCESS
      # The user has been authorised with OpenID, now to find them in PMOG
      identity_url = Url.normalise(response.identity_url)
      
      if identity_url.to_s == "0" or ! identity_url
        flash[:error] = "Could not log on with your OpenID"
        redirect_to new_openid_url and return
      else
        self.current_user = User.find( :first, :conditions => { :identity_url => identity_url } )
      end

      if logged_in?
        # Remember me
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }

        flash[:notice] = "Logged in successfully"
        redirect_to '/' and return
      else
        # Try again or register?
        flash[:error] = "Could not log on with your OpenID"
        redirect_to new_openid_url and return
      end
    else
      # Good old error
      flash[:error] = "Could not log on with your OpenID"
      redirect_to new_openid_url and return
    end
  end

  protected
  def openid_consumer
    @openid_consumer ||= OpenID::Consumer.new(session,      
      OpenID::FilesystemStore.new("#{RAILS_ROOT}/tmp/openid"))
  end
end