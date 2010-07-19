class SuspensionsController < ApplicationController
  before_filter :login_required
  permit 'site_admin or steward'

  # There is a helper method in the users helper to display a link to suspend or restore
  # depending on what action is called here. As such, we need to include the helper so
  # the rjs calls can replace the link dynamically.
  helper :users

  before_filter :check_admin

  def index
    unless site_admin? or steward?
      flash[:notice] = "That wasn't the page you were looking for."
      redirect_to '/'
      return
    end

    @page_title = "People currently on vacation from "

    @suspensions = Suspension.find(:all, :conditions => ["expires_at > ?", Time.now.to_s(:db)], :order => "created_at DESC")
  end


  def form
    unless site_admin? or steward?
      flash[:notice] = "You can't suspend people."
      redirect_to '/'
      return
    end

    @user = User.find_by_login(params[:id])

    if @user.has_role? 'site_admin' or @user.has_role? 'steward'
      flash[:notice] = "You can't suspend admins."
      redirect_to '/'
      return
    end

    @page_title = "Put the frighteners on #{@user.login}? On "
  end

  # Action called to suspend a player.
  def suspend
    # Get the user from the url ID
    @user = User.find_by_login(params[:id])

    # Build the suspension object using the association proxy
    @suspension = @user.suspensions.build(params[:suspension])

    # If the save is successful, then set the flash message and let the rjs dynamically update the profile page.
    if @suspension.save
      @user.expire_cache('suspended?')
      flash[:notice] = "#{@user.login} has been suspended from #{@suspension.created_at} until #{@suspension.expires_at}"
      respond_to do |format|
        format.js
        format.html {
          redirect_to user_path(@user)
        }
      end
    else
      # Otherwise, show the same form again but redraw it to show the errors.
      render :update do |page|
        page.replace_html "suspend_form", :partial => "suspensions/suspend_form", :locals => { :user => @user }
      end
    end
  end

  # Someone is giving the benefit of the doubt and is prematurely restoring a suspended user
  def restore
    # Get the user by the url ID
    @user = User.find_by_login(params[:id])

    # Get the suspension with the most recent expiration
    @suspension = @user.suspensions.first

    # If it's not already expired, then set it to expire immediately
    if @suspension.expires_at.after? Time.now

      @suspension.expires_at = Time.now.to_s(:db)

      if @suspension.save
        @user.expire_cache('suspended?')
        respond_to do |format|
          flash[:notice] = "#{@user.login} has been restored"
          format.html { redirect_to user_path(@user.login) }
          format.js
        end
      else
        # Otherwise, redirect to the user profile and show an error.
        respond_to do |format|
          flash[:notice] = "Unable to restore #{@user.login} at this time"
          format.html { redirect_to user_path(@user.login) }
          format.js {
            render :update do |page|
              page.replace_html "flash_msg", :partial => "shared/flash", :locals => { :flash => flash }
              flash.discard
            end
          }
        end
      end
    else
      # Otherwise, they aren't currently suspended!
      respond_to do |format|
        flash[:notice] = "#{@user.login} isn't currently suspended!"
        format.html { redirect_to user_path(@user.login) }
        format.js {
          render :update do |page|
            page.replace_html "flash_msg", :partial => "shared/flash", :locals => { :flash => flash }
            flash.discard
          end
        }
      end
    end
  end

  private

  # Make sure that we're an admin. Don't want the script kiddies exploiting this!
  def check_admin
    unless site_admin? or steward?
      flash[:error] = "You're not allowed there!"
      redirect_to user_path( current_user )
    end
  end
end
