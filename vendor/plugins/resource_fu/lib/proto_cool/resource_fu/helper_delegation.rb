module ProtoCool::ResourceFu::HelperDelegation

  def delegate_resources_helpers(*delegations)
    options = delegations.pop
    delegated = delegations.pop
    if delegated.nil? || options[:to].nil?
      raise ArgumentError, "Helper delegation expects arguments like ':images, :to => :user_images'"
    end

    target = options[:to].to_s
    target_singular = target.singularize
    delegated = delegated.to_s
    delegated_singular = delegated.singularize
    
    ActionController::Routing::Routes.named_routes.select {|name,route| route.requirements[:controller] == target}.each do |name, route|
      if name.to_s =~ /#{target}/
        delegate_url_helpers name.to_s.gsub(/#{target}/, delegated), :to => name
      elsif name.to_s =~ /#{target_singular}/
        delegate_url_helpers name.to_s.gsub(/#{target_singular}/, delegated_singular), :to => name
      else
        raise ArgumentError, "Unable to figure out how to delegate for route: #{name.inspect}"
      end
    end
  end

  def delegate_url_helpers(*delegations)
    options = delegations.pop
    delegated = delegations.pop

    case
    when delegated.nil? && Class === options[:for]
      options[:for].delegated_url_helpers.each do |new_helper, delegated_helper|
        delegate_url_helper(new_helper, delegated_helper)
      end
    when delegated && options[:to]
      ['_path', '_url'].each do |helper_type|
        delegate_url_helper(delegated.to_s + helper_type, options[:to].to_s + helper_type)
      end
    else
      raise ArgumentError, "Helper delegation expects arguments like ':foo, :to => :bar' or ':for => Controller'"
    end
  end

  def delegate_url_helper(new_helper, delegated_helper)
    module_eval(<<-EOS, "(__DELEGATED_HELPERS_#{new_helper.to_s}__)", 1)
      def #{new_helper.to_s}(*args)
        #{delegated_helper.to_s}(*args)
      end
      helper_method #{new_helper.to_sym.inspect}
      protected #{new_helper.to_sym.inspect}
    EOS
    (@delegated_url_helpers ||= {})[new_helper.to_s] = delegated_helper.to_s
  end

  def delegated_url_helpers
    (@delegated_url_helpers ||= {}).dup
  end

end
