class UserAssetsController < AssetsController

  # These are resource_fu methods.
  delegate_resources_helpers :assets, :to => :user_assets
  delegate_url_helpers :asset_attachable, :to => :user

  # Keep it DRY - we only need one set of templates
  def self.controller_path
    AssetsController.controller_path
  end

protected
  def load_attachable
    # We do both @user and @attachable because @attachable is used by the assets_controller
    # and @user is used when inferring missing path segments in the url helpers
    @user = @attachable = User.find_by_param(params[:user_id])
  end
  
  # This is implemented on a per-polymorph basis because the asset.attachable may be
  # an object that is *indirectly* tied to the current user.
  def check_auth
    @user == current_user or raise AccessDenied
  end
end