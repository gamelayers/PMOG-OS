module Dismissible
  module Controller  
    def self.included(base)
      base.send :helper_method, :cookies
    end
  end
  
  module Helpers
    def dismissible_message(id, opts={}, &block)
      opts.reverse_merge!({ :message => "Don't show this again.", :class => "dismissible_message", :follows => nil })
      id = "hide_dismissible_#{id}"
      
      return if cookies[id]
      
      return if opts[:follows] && !cookies["hide_dismissible_#{opts[:follows]}"]
      
      concat(content_tag(:div, 
        capture(&block) + %{#{link_to_dismiss(id,opts)}</p>}, 
        :class => opts[:class], :id => id), 
        block.binding)    
    end
    
    def link_to_dismiss(id, opts)
      expires = CGI.rfc1123_date(5.years.from_now) # Cookie expires 5 years in the future.
      link_to_function(opts[:message], dismissal_javascript_for(id, expires), { :class => "dismissible_link" })
    end
    
    def dismissal_javascript_for(id, expires)
      "document.cookie = '#{id} = 1; expires=#{expires}; path=/';document.getElementById('#{id}').style.display = 'none'"
    end
  end
end