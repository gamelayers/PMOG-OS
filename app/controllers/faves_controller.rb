class FavesController < ApplicationController
  before_filter :login_required, :only => :create

  # GET /faves
  # GET /faves.json
  # GET /users/login/faves
  # GET /users/login/faves.json
  def index
    params[:user_id] ? list(params[:user_id], params[:page]) : top(params[:period], params[:page])
  end


  # POST /location/location_id/faves.js
  def create
    @fave = Fave.create_and_deposit(current_user, params)
    flash[:notice] = "Faved!"

    respond_to do |format|
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 201
        flash.discard
      end
    end
  rescue Exception => e
    flash[:error] = e.message
    respond_to do |format|
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => render_full_json_response(:flash => flash), :status => 422
        flash.discard
      end
    end
  end

  protected
  def top(period, page)
    @faves = Fave.top(period, page)
    @page_title = "The Top Faves on "

    respond_to do |format|
      format.html { render :action => :top } # top.html.erb
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => @faves.collect{ |f| [f.id, f.location.id, f.created_at] }.to_json
      end
    end
  end

  def list(user_id, page)
    @user = User.find_by_login(user_id)
    @faves = Fave.latest_for(@user, page)
    @page_title = @user.login + "'s Faves on "

    respond_to do |format|
      format.html { render :action => :list } # list.html.erb
      format.json do
        response.headers["Content-Type"] = "text/json; charset=utf-8"
        render :json => @faves.collect{ |f| [f.id, f.location.id, f.created_at] }.to_json
      end
    end
  end
end
