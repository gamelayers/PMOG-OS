class BirdBotAssetsController < AssetsController

  # These are resource_fu methods.
  delegate_resources_helpers :assets, :to => :bird_bot_assets
  delegate_url_helpers :asset_attachable, :to => :bird_bot

  # Keep it DRY - we only need one set of templates
  def self.controller_path
    AssetsController.controller_path
  end

protected
  def load_attachable
    # We do both @bird_bot and @attachable because @attachable is used by the assets_controller
    # and @bird_bot is used when inferring missing path segments in the url helpers
    @bird_bot = @attachable = BirdBot.find_by_param(params[:bird_bot_id])
  end
  
  # This is implemented on a per-polymorph basis because the asset.attachable may be
  # an object that is *indirectly* tied to the current user.
  def check_auth
    @bird_bot.user == current_user or raise AccessDenied
  end
end