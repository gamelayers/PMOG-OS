module ProtoCool::ResourceFu::NamedRouteCollectionMethods
  class << self
    def included(base)
      base.class_eval do
        alias_method_chain :define_url_helper, :inferences
      end
    end
  end

  def define_url_helper_with_inferences(route, name, kind, options)
    selector = url_helper_name(name, kind)
    hash_access_method = hash_access_name(name, kind)
    ProtoCool::ResourceFu::MethodDefinition.define_module_url_helper_method(@module, selector, hash_access_method, route, name, kind, options)
    @module.send(:protected, selector)
    
    helpers << selector
  end
  private :define_url_helper_with_inferences
end

