#NOTE # The "rescue Exception => e" blocks here intentionally pass all errors forward becuase the model is responsible for stopping nastier shit itself
# The idea is to thin up the controller a bit, if possible

class GiftcardsController < ApplicationController
  before_filter :login_required
  ##before_filter :authenticate, :only => :index
  before_filter :load_giftcard, :only => [:loot, :destroy, :dismiss]
  before_filter :no_backsies, :only => :loot
  permit 'site_admin', :only => [ :index, :search, :destroy ]

  def index
    @giftcards = Giftcard.paginate( :all,
      :order => 'giftcards.created_at DESC',
      :page => params[:page],
      :per_page => 100 )

    render :action => 'list'
  end

  def search
    return unless site_admin?

    case params[:criteria]
    when "location"
      @giftcards = Giftcard.paginate(:all, :include => [:user, :location], :conditions => ['giftcards.location_id = locations.id and locations.url = ?', params[:q]], :page => params[:page], :per_page => 100, :order => "giftcards.created_at DESC")
      @page_title = "Giftcards on location -- #{params[:q]}"
      @h1content = "Giftcards on #{params[:q]}"
    when "user"
      @searcheduser = User.find_by_login(params[:q])
      @giftcards = Giftcard.paginate(:all, :include => [:user, :location], :conditions => ['giftcards.user_id = ?', @searcheduser.id], :order => "giftcards.created_at DESC", :page => params[:page], :per_page => 100)
      @page_title = "User #{params[:q]}'s giftcards "
      @h1content = "#{params[:q]}'s Giftcards"
    end
  end

  def attach
    begin
      target_player = User.find( :first, :conditions => { :login => params[:user_id] } )
      Giftcard.create_and_deposit(current_user, {:location_id => Location.caches( :find_or_create_by_url, :with => "http://thenethernet.com/users/#{target_player.login}").id })

      respond_to do |format|
        flash[:notice] = "#{Ability.cached_single(:giftcard).name} bribe left for #{params[:user_id]}!"
        format.json {
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        }
      end
    rescue ActiveRecord::RecordNotFound => e
      handle_giftcard_error("Invalid player specified")
    rescue PMOG::PMOGError => e
      handle_giftcard_error(e.message)
    rescue Exception => e
      log_exception(e)
      handle_giftcard_error("An error has occured, please try again.")
    end
  end

  def create
    begin
      @giftcard = Giftcard.create_and_deposit(current_user, params)

      respond_to do |format|
        flash[:notice] = "#{Ability.cached_single(:giftcard).name.singularize} stashed!"
        format.json {
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        }
        format.js # Let the RJS handle this shiz.
      end
    rescue PMOG::PMOGError => e
      handle_giftcard_error(e.message)
    rescue Exception => e
      log_exception(e)
      handle_giftcard_error("An error has occured, please try again.")
    end
  end

  # PUT /location/location_id/giftcards/id/loot.js
  def loot
    Giftcard.transaction do
      params[:avatar_path] = "#{host}#{avatar_path_for_user(:user => current_user, :size => "tiny")}"

      begin
        @giftcard.loot(current_user, params)
        @giftcard.destroy
        record_awsm :user => current_user, :cardlayer => @giftcard.user, :location => @giftcard.location
      rescue PMOG::PMOGError => e
        handle_giftcard_error(e.message, 401)
        return
      rescue Exception => e
        log_exception(e)
        handle_giftcard_error("An unhandled exception has occured, please try again.")
        return
      end
    end

    # tell the client the event was successful.  no data required, just the status code.
    respond_to do |format|
      format.json {
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => {:gift_giver => @giftcard.user.login}, :status => '200'
      }
    end
  end

  # DELETE /location/location_id/crates/1.js
  def destroy
    if ! params[:delete_these].blank?
      Giftcard.destroy(params[:delete_these])

      flash[:notice] = 'Giftcards destroyed'
      redirect_to :action => 'index'
    else
      @giftcard.destroy

      flash[:notice] = 'Giftcard destroyed'
      redirect_to :action => 'index'
    end
  end

  # POST /locations/location_id/giftcards/id/dismiss.js
  # Dismiss this overlay, so that the user doesn't see it again
  def dismiss
    begin
      @giftcard.dismiss(current_user, params)

      flash[:notice] = "DP Card dismissed!"
      respond_to do |format|
        format.json {
          response.headers["Content-Type"] = "text/json; charset=utf-8"
          render :json => render_full_json_response(:flash => flash), :status => 201
          flash.discard
        }
      end
    rescue Exception => e
      handle_giftcard_error(e.message)
    end
  end

  protected
  def load_giftcard
    if (params[:id])
      begin
        @giftcard = Giftcard.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        handle_giftcard_error("The DP Card you were trying to loot is already gone!")
        return
      end
    end
  end

  def no_backsies
    begin
      if current_user == @giftcard.user and not site_admin?
        raise Giftcard::BacksiesError.new
      end
    rescue Giftcard::BacksiesError => e
      handle_giftcard_error(e.message, 401)
      return
    end
  end

  def handle_giftcard_error(msg, status = 422)
    flash[:error] = msg
    respond_to do |format|
      format.json do
        render :json => render_full_json_response(:flash => flash), :status => status
        flash.discard
      end
    end
  end
end
