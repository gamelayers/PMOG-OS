#
# As you read this, bear in mind that this controller
# is involved in a polymorphic relationship and should
# *never* appear directly in a route.  
# 
# Create subclasses that know how to deal with the 
# specifics of the relationship between the Asset and
# its polymorhpic 'attachable' (see UserAssetsController).
#
# Another option would be to put all of this stuff into a
# module that the polymorphs would include().  However
# doing it this way means we just have one set of templates
# under app/views/assets that are re-used by the polymorphs.
# See self.controller_path in UserAssetsController.
#
class AssetsController < ApplicationController

  protected_actions = [ :index, :new, :create, :edit, :update, :destroy ]
  before_filter :load_attachable
  before_filter :load_asset, :except => [ :index, :create, :new ]
  before_filter :check_auth, :only => protected_actions
  
protected

  # assets() is used for find() and build()
  delegate :assets, :to => '@attachable'
  helper_method :assets
  
  def load_asset
    @asset = assets.find(params[:id])
  end

  def check_auth
    current_user == @asset.user or raise AccessDenied
  end

public

  # GET /assets
  # GET /assets.xml
  def index
    @assets = assets.find(:all)

    respond_to do |format|
      format.html
    end
  end

  # GET /assets/1
  # GET /assets/1.xml
  def show
    respond_to do |format|
      format.html
    end
  end

  # GET /assets/new
  def new
    @asset = assets.build
    @page_title = 'Something New for '
  end

  # GET /assets/1;edit
  def edit
  end

  # POST /assets
  # POST /assets.xml
  def create
    @asset = assets.build(params[:asset])

    # We don't support multiple assets
    clear_other_assets

    respond_to do |format|
      if @asset.save
        if @asset.attachable_type == 'User'
          # Clear cached (default) assets
          ['large', 'medium', 'small', 'tiny', 'toolbar', 'mini'].each do |size|
            Asset.expire_cache("#{@asset.id}:public_filename:#{size}")
          end
        end
        flash[:notice] = 'Image was successfully uploaded.'
        format.html { redirect_to :controller => self.controller_name, :action => 'edit', :id => @asset.id }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  # PUT /assets/1
  # PUT /assets/1.xml
  def update
    # We don't support multiple assets
    clear_other_assets

    respond_to do |format|
      if @asset.update_attributes(params[:asset])

        # Redirect to show the relevant attachable type
        format.html {           
          if @asset.attachable_type == 'User'

            # Clear cached assets
            ['large', 'medium', 'small', 'tiny', 'toolbar', 'mini'].each do |size|
              Asset.expire_cache("#{@asset.id}:public_filename:#{size}")
            end

            # Delete the user cache, and the cache of all that users buddies
            # so that the new avatar exists across all pages where you face may appear,
            # so far, missions and posts
            User.expire_cache(@asset.attachable_id)
            User.expire_cache(@asset.attachable.login)

            @asset.attachable.buddies.each do |buddy|
              User.expire_cache(buddy.id)
              User.expire_cache(buddy.login)
            end

            @asset.attachable.missions.each do |mission|
              Mission.expire_cache(mission.url_name)
            end
            
            @asset.attachable.missions.completed.each do |mission|
              Mission.expire_cache(mission.url_name)
            end

            @asset.attachable.topics.each do |topic|
              Topic.expire_cache( "topic_#{topic.url_name}" )
            end

            redirect_to user_path(@asset.attachable)
          elsif @asset.attachable_type == 'Npc'
            redirect_to npc_path(@asset.attachable)
          elsif @asset.attachable_type == 'BirdBot'
            redirect_to bird_bot_path(@asset.attachable)
          else
            redirect_to asset_url(@asset)
          end
        }
      else
        format.html { render :action => 'edit' }
      end
    end
  end

  # DELETE /assets/1
  # DELETE /assets/1.xml
  def destroy
    @asset.destroy

    respond_to do |format|
      format.html { redirect_to assets_url() }
    end
  end
  
  protected
  def clear_other_assets
    @asset.attachable.assets.each do |a|
      a.destroy unless a == @asset
    end
  end
end
