class NpcsController < ApplicationController
  before_filter :login_required, :except => [ :index, :show ]

  # GET /npcs
  # GET /npcs.xml
  def index
    @npcs = Npc.find(:all, :include => [ :assets, :user, :tags ], :group => "npcs.id")

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @npcs.to_xml }
    end
  end

  # GET /npcs/1
  # GET /npcs/1.xml
  def show
    @npc = Npc.find_by_url_name(params[:id], :include => [ :assets, :locations, :feeds, :users, :user ], :group => "npcs.id")

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @npc.to_xml }
    end
  end

  # GET /npcs/new
  def new
    @npc = Npc.new
  end

  # GET /npcs/1;edit
  def edit
    @npc = Npc.find_by_url_name(params[:id])
    check_auth
  end

  # POST /npcs
  # POST /npcs.xml
  def create
    @npc = current_user.npcs.build( params[:npc] )

    respond_to do |format|
      if @npc.save
        flash[:notice] = 'Npc was successfully created.'
        format.html { redirect_to new_npc_npc_asset_path() }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /npcs/1
  # PUT /npcs/1.xml
  def update
    @npc = Npc.find_by_url_name(params[:id])
    check_auth

    respond_to do |format|
      if @npc.update_attributes(params[:npc])
        flash[:notice] = 'Npc was successfully updated.'
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /npcs/1
  # DELETE /npcs/1.xml
  def destroy
    @npc = Npc.find(params[:id])
    check_auth
    @npc.destroy

    respond_to do |format|
      format.html { redirect_to npcs_url }
    end
  end

  # Subsribe to this bots feed
  def subscribe
    @npc = Npc.find(params[:id])
    unless @npc.users.include? current_user
      @npc.users << current_user 
      @npc.save
    end
    render :text => "You are subscribed to this NPC"
  end

  # Unsubscribe from this bots feed
  def unsubscribe
    @npc = Npc.find(params[:id])
    if @npc.users.include? current_user
      @npc.users.delete(current_user)
      @npc.save
    end
    render :text => "You are unsubscribed from this NPC"
  end

  protected
  def check_auth
    @npc.user == current_user or redirect_to npcs_url
  end
end