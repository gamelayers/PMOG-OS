# DistributedAssets
require 'zlib'

module Scoop
  module DistributedAssets # :nodoc:
    module AssetTagHelper
      def self.included(base)
        # Yes, I'm looking forward to Rails 1.2's alias_method_chain
        base.send :alias_method, :compute_public_path_without_random_asset_host, :compute_public_path
        base.send :alias_method, :compute_public_path, :compute_public_path_with_random_asset_host
      end

      private
        # Fix for 'wrong number of arguments (2 for 3) on edge rails - duncan 16/10/07
        #def compute_public_path_with_random_asset_host(source, dir, ext)
        def compute_public_path_with_random_asset_host(source, dir, ext = nil)
          source = compute_public_path_without_random_asset_host(source, dir, ext)
          
          unless source =~ %r{^[-a-z]+://} or ActionController::Base.asset_hosts.blank?
            idx = (Zlib.crc32(source || "error" ) % ActionController::Base.asset_hosts.size)
            source = ActionController::Base.asset_hosts[idx] + source
          end
          source
        end
    end
    
    module ActionControllerExtension
      def self.included(base)
        base.class_eval <<-EOF
          @@asset_hosts = []
          cattr_accessor :asset_hosts        
        EOF
        
        if base.asset_host.is_a?(Array)
          base.asset_hosts = base.asset_host
          base.asset_host = ""
        end
      end
    end
      
  end
end