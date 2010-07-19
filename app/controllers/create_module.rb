module CreateModule

  # Register for PMOG! Note that a lot of code is triggered in the user observer as a result of this.
  def create # will do a FIND first!
    # Since we're not making the user confirm their password anymore
    # this will make the validation work.
    if not params["user"]["password"].empty?
      params["user"]["password_confirmation"] = params["user"]["password"]
    end

    begin
        @user = User.create(params["user"])
        @user.reload

        # Build the UserSecret object if the params have the data.
        if params["user_secret"]
          secret = @user.build_user_secret(params["user_secret"])
          secret.save!
        end

        if !cookies[:share].nil?
          @share = MissionShare.find(cookies[:share])
          @share.convert!
        end

        Crate.create_on_profile(Location.find_or_create_by_url( 'http://' + request.env[ 'HTTP_HOST' ] + '/users/' + @user.login ))

        # Connect the BetaKey to the user, so that we can see who invited this user
        # the invite event (if it occurs) is hidden inside this call as well
        if cookies[:beta_key]
          User.set_betakey_for(@user, cookies[:beta_key])
        else
          Event.record :context => 'signup',
            :user_id => @user.id,
            :message => 'signed up!'
        end

        self.current_user = User.authenticate(@user.login, params[:user][:password])

        # Allow the user to login, too
        cookies[:auth_token] = { :value => @user.remember_token, :expires => @user.remember_token_expires_at }

        # NOTE disabled
        ## Set this variable in the session so we can track who is a new user and control their layout experience.
        #session[:new_user] = true

        respond_to do |format|
          format.html {
            flash[:notice] = 'You have successfully signed up for The Nethernet!'
            redirect_to(@share.nil? ? "/home/install/" : mission_path(@share.mission))
          }
          format.js
          format.json {
            render :json => create_new_session_overlay
          }
        end

    rescue ActiveRecord::RecordInvalid
      flash[:notice] = "There is an invalid record preventing the user account from being created"
      respond_to do |format|
        format.html {
          render :action => "new"
        }
        format.js {
          render :action => "create_fail"
        }
        format.json {
          render :json => render_full_json_response(:flash => flash, :errors => @user.errors), :status => 406
        }
      end
    #rescue Exception => e
    #  flash[:notice] = "There was a problem signing up, please try again. " + e
    #  respond_to do |format|
    #    format.html {
    #      render :action => "new"
    #    }
    #    format.js {
    #      render :action => "create_fail"
    #    }
    #    format.json {
    #      render :json => render_full_json_response(:flash => flash, :errors => @user.errors), :status => 406
    #    }
    #  end
    end
  end
end
