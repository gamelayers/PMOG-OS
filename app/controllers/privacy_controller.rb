# Privacy controller to allow users to delete their browsing data or close their account
class PrivacyController < ApplicationController
  before_filter :login_required, :except => :goodbye
  before_filter :check_referrer, :only => [ :delete_history, :close_account ]
  
  # Deprecated, is now part of the edit user page
  def index
    redirect_to "/users/#{current_user.login}/edit?section=6"
  end
  
  def delete_history
    redirect_to :action => 'index' and return unless request.post? # post only, no gets, csrf protected too
    
    # Only delete the history if the user has confirmed their password correctly
    # - delete the daily_domains in batches of 100, rather than one huge query
    if current_user.password != '' and current_user.authenticated?(params[:user][:password_confirmation])
      # Delete surfing history as a background job as it takes too long to process in one go
      # - use the current_user.id in the background job since the account may be deleted when we try to run the delete
      # - only deletes records in the current daily domains table
      Cron.submit_bj_task_from_production("./script/runner ./jobs/delete_history.rb #{current_user.id} -e cron", "delete_history_#{current_user.login}")
      flash[:notice] = "Your PMOG history has been deleted"
      redirect_to :action => "index"
    else
      flash[:notice] = 'Passwords do not match.'
      redirect_to :action => 'index'
    end
  end
  
  def close_account
    redirect_to :action => 'index' and return unless request.post? # post only, no gets, csrf protected too
    return if current_user.id == User.find_by_email( 'self@pmog.com' ).id # no funny business, alright?
    return if site_admin? # no, really
    
    # Only delete the history if the user has confirmed their password correctly
    if current_user.password != '' and current_user.authenticated?(params[:user][:password_confirmation])
      # Let's delete everything by hand, that we can remember to get rid of
      # Then we'll use user.destroy to catch anything else
      
      # Missions, bird bots, npcs, topics, posts, comments, beta users and events
      current_user.missions.collect{ |m| m.destroy }
      current_user.bird_bots.collect{ |b| b.destroy }
      current_user.npcs.collect{ |n| n.destroy }
      current_user.topics.collect{ |t| t.destroy }
      current_user.posts.collect{ |p| p.destroy }
      
      [ :mines, :crates, :portals, :st_nicks, :lightposts ].each do |tool|
        current_user.send(tool).collect{ |t| t.destroy }
      end

      BetaUser.find( :all, :conditions => { :email => current_user.email } ).collect{ |b| b.destroy }
      Comment.find( :all, :conditions => { :user_id => current_user.id } ).collect{ |c| c.destroy }
      Event.find( :all, :conditions => { :user_id => current_user.id } ).collect{ |e| e.destroy }
      Mission.find( :all, :conditions => { :user_id => current_user.id } ).collect{ |m| m.destroy }
        
      # Now delete the session, cookie and any remaining user data
      user = current_user
      user.forget_me if logged_in?
      cookies.delete :auth_token
      reset_session
      
      # And now delete any cache that is relevant, this probably needs 
      # to be more than just missions, but I'll add to that later...
      Mission.expire_cache( "latest_missions_5" )
      
      User.execute( "DELETE FROM buddies_users WHERE buddy_id = '#{user.id}'")
      User.execute( "DELETE FROM buddies_users WHERE user_id = '#{user.id}'")

      # Delete surfing history as a background job as it takes too long to process in one go
      # - use the current_user.id in the background job since the account may be deleted when we try to run the delete
      Cron.submit_bj_task_from_production("./script/runner ./jobs/delete_history.rb #{current_user.id} -e cron", "delete_account_and_history_#{current_user.login}")
      
      user.destroy # will delete anything marked 'dependent => destroy' in user.rb

      flash[:notice] = "Your PMOG account has been closed"
      redirect_to :controller => "privacy", :action => "goodbye"
    else
      flash[:notice] = 'Passwords do not match.'
      redirect_to :action => 'index'
    end
  end
  
  # Updates the privacy settings the user has set for themselves
  # and clears the relevant caches
  def update_privacy
    @user = User.find_by_id(current_user.id)
    params[:preference].each { |key,value|
      @user.preferences.set key.split("-")[5], value
      current_user.preferences.expire_cache( "get_#{key}" )
    }

    current_user.preferences.expire_cache( "privacy_options_for_#{current_user.id}" )
    flash[:notice] = "Privacy Preferences Saved"
    redirect_to "/users/#{current_user.login}/edit?section=6"
  end
  
  # Updates the email preference the user has set for themselves.
  def update_email_prefs
    if params[:preference]
      idstringarr = params[:preference].first[0].scan(/(.*-){5}(.*)/)
      #params[:preference]["#{current_user.id}-#{params[:key]}"] == 'true'
      if params[:preference]["#{current_user.id}-#{idstringarr[0][1]}"] == 'true'
        current_user.preferences.set idstringarr[0][1], true
      else
        current_user.preferences.set idstringarr[0][1], false
      end
    end
    flash[:notice] = "Email Notification Preferences Saved"
    respond_to do |format|
      format.html {
        redirect_to :action => :index
      }
      format.js
    end
end

  # TODO - This can be merged with the above "update email prefs" as they do the same thing
  #        They're separate now because this one uses hot ajaxiness and the above does not.
  # Processes changes in boolean preferences. i.e; yes or no
  def boolean_prefs
    @user = User.find_by_id(current_user.id)
      params[:preference].each { |key,value| 
        if value == "on" or value == "off"
          @user.preferences.set key.split("-")[5], value == "on"? true : false
        else
          @user.preferences.set key.split("-")[5], value
        end
        User.expire_cache(@user.login)
        User.expire_cache("find_by_login:#{@user.login}")
        @user.preferences.expire_cache("get_#{key}")
        @user.preferences.expire_cache("setting_#{key}")

        flash[:notice] = "Content Preferences Saved"
        respond_to do |format|
          format.html {
            redirect_to :action => :index
          }
          format.js
        end

        # render :update do |page|
        #   page.replace_html "flash", "<p style=\"color:green\">#{key.split("-")[5]} successfully updated!</p>"
        #   page[:flash].show
        #   page[:flash].visual_effect :pulsate, :duration => 5, :queue => {:position => 'end', :scope => 'flash'}
        #   page[:flash].visual_effect :fade, :duration => 1, :queue => {:position => 'end', :scope => 'flash'}
        # end
      }
  end 
end
