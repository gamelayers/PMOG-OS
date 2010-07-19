class BirdBotsController < ApplicationController
  before_filter :login_required, :except => [ :index, :show ]

  # GET /bird_bots
  # GET /bird_bots.xml
  def index
    @bird_bots = BirdBot.find(:all, :include => [ :assets, :user, :tags ], :group => 'bird_bots.id')

    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # GET /bird_bots/1
  # GET /bird_bots/1.xml
  def show
    @bird_bot = BirdBot.find_by_url_name(params[:id], :include => [ :assets, :locations, :users, :feed, :user ], :group => 'bird_bots.id')

    respond_to do |format|
      format.html # show.rhtml
    end
  end

  # GET /bird_bots/new
  def new
    @bird_bot = BirdBot.new
  end

  # GET /bird_bots/1;edit
  def edit
    @bird_bot = BirdBot.find_by_url_name(params[:id])
    check_auth
  end

  # POST /bird_bots
  # POST /bird_bots.xml
  def create
    @bird_bot = current_user.bird_bots.build( params[:bird_bot] )

    respond_to do |format|
      if @bird_bot.save
        flash[:notice] = 'BirdBot was successfully created.'
        format.html { redirect_to new_bird_bot_bird_bot_asset_path() }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  # PUT /bird_bots/1
  # PUT /bird_bots/1.xml
  def update
    @bird_bot = BirdBot.find_by_url_name(params[:id])
    check_auth

    respond_to do |format|
      if @bird_bot.update_attributes(params[:bird_bot])
        flash[:notice] = 'BirdBot was successfully updated.'
        format.html { redirect_to bird_bot_url(@bird_bot) }
      else
        format.html { render :action => 'edit' }
      end
    end
  end

  # DELETE /bird_bots/1
  # DELETE /bird_bots/1.xml
  def destroy
    @bird_bot = BirdBot.find(params[:id])
    check_auth
    @bird_bot.destroy

    respond_to do |format|
      format.html { redirect_to bird_bots_url }
    end
  end

  # Subsribe to this bots feed
  def subscribe
    @bird_bot = BirdBot.find(params[:id])
    unless @bird_bot.users.include? current_user
      @bird_bot.users << current_user 
      @bird_bot.save
    end
    render :text => 'You are subscribed to this bird bot'
  end
  
  # Unsubscribe from this bots feed
  def unsubscribe
    @bird_bot = BirdBot.find(params[:id])
    if @bird_bot.users.include? current_user
      @bird_bot.users.delete(current_user)
      @bird_bot.save
    end
    render :text => 'You are unsubscribed from this bird bot'
  end
  
  protected
  def check_auth
    @bird_bot.user == current_user or redirect_to bird_bots_url
  end
end