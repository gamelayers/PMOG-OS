require 'scoop/distributed_assets'
ActionView::Helpers::AssetTagHelper.send(:include, Scoop::DistributedAssets::AssetTagHelper)
ActionController::Base.send(:include, Scoop::DistributedAssets::ActionControllerExtension)