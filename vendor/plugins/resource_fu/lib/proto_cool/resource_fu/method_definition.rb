class ProtoCool::ResourceFu::MethodDefinition

  # define a url helper method in an arbitrary module
  def self.define_module_url_helper_method(target_module, selector, hash_access_method, route, name, kind, options)
    # The segment keys used for positional paramters
    segment_keys = route.segments.collect do |segment|
      segment.key if segment.respond_to? :key
    end.compact
    
    # The local variable inferences for each positional parameter
    inference_cases = []
    segment_keys.each_with_index do |segment_key, index|
      next if segment_key == :id # never infer :id
      inference_cases << inference_case(segment_key, index)
    end

    target_module.send :module_eval, <<-end_eval # We use module_eval to avoid leaks
    def #{selector}(*args)
      opts = #{hash_access_method}(Hash === args.last ? args.pop : nil)
      raise ArgumentError, "expected a maximum of #{segment_keys.length} positional arguments for route" if args.length > #{segment_keys.length}
      
      offset = #{segment_keys.length} - args.length
      #{segment_keys.inspect}.each_with_index do |key, index|
        if (index - offset) >= 0
          # supplied positional args always go in
          opts[key] = args[index - offset]
        else
          # never overwrite an explicitly passed param with an inferred one
          next if opts.has_key?(key)
          case index
          #{inference_cases}
          when nil 
            # bogus when condition to stop ruby from complaining at compile time
          end
        end
      end
      url_for(opts)
    end
    end_eval
  end
  
  def self.inference_case(key, index)
    key_without_id = key.to_s.gsub(/_id$/,'').to_sym
    <<-end_eval
    when #{index}
      if inferred_val = @#{key_without_id} || @#{key}
        opts[key] = inferred_val
      end
    end_eval
  end

end

