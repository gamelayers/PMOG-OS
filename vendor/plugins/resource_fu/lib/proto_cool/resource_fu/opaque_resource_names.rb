# Opaque names are the name of the resource as it appears in your URL.
module ProtoCool::ResourceFu::OpaqueResourceNames
  class << self
    def included(base)
      base.class_eval do
        alias_method_chain :path, :opaque_name
      end
    end
  end

  def path_with_opaque_name
    @path ||= "#{path_prefix}/#{(options[:opaque_name] || plural).to_s}"
  end
end
