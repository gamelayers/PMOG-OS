require 'proto_cool/resource_fu'
require 'proto_cool/resource_fu/method_definition'
require 'proto_cool/resource_fu/named_route_collection_methods'
require 'proto_cool/resource_fu/opaque_resource_names'
require 'proto_cool/resource_fu/helper_delegation'

# add url_helper inferencing code to NamedRouteCollection
ActionController::Routing::RouteSet::NamedRouteCollection.send(:include, ProtoCool::ResourceFu::NamedRouteCollectionMethods)
# add opaque_name argument to Resource
ActionController::Resources::Resource.send(:include, ProtoCool::ResourceFu::OpaqueResourceNames)
# add helper delegation to ActionController::Base
ActionController::Base.extend ProtoCool::ResourceFu::HelperDelegation