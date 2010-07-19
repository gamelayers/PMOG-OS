class NpcAssetsController < AssetsController

  # These are resource_fu methods.
  delegate_resources_helpers :assets, :to => :npc_assets
  delegate_url_helpers :asset_attachable, :to => :npc

  # Keep it DRY - we only need one set of templates
  def self.controller_path
    AssetsController.controller_path
  end

protected
  def load_attachable
    # We do both @npc and @attachable because @attachable is used by the assets_controller
    # and @npc is used when inferring missing path segments in the url helpers
    @npc = @attachable = Npc.find_by_param(params[:npc_id])
  end
  
  # This is implemented on a per-polymorph basis because the asset.attachable may be
  # an object that is *indirectly* tied to the current user.
  def check_auth
    @npc.user == current_user or raise AccessDenied
  end
end