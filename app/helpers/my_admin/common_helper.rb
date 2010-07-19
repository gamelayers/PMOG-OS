module MyAdmin::CommonHelper
  
  def ajax_link(link, url)
    link_to_remote(link, :url => url, :post => true, :loading => 'loading()', :complete => 'loaded()')
  end

  def ajax_link_confirm(link, url, confirm_txt = "Are you sure?")
    if confirm_destroy
      link_to_remote(link, :url => url, :post => true, :loading => 'loading()', :complete => 'loaded()', :confirm => confirm_txt)
    else
      ajax_link(link, url)
    end
  end
  
  # Nicely prints a Date or Time (ex: "January 12, 2007")
  def nice_print(dt)
    return '' if dt.nil?
    dt.strftime("%b %d, %Y %H:%M:%S %Z")
  end
  
  def column_options(columns)
    opts = ''
    columns.each do |col|
      if col.name == "user_id"
        opts << "<option value=\"login\">User Login</option>"
      else
        opts << "<option value=\"#{col.name}\">#{truncate(col.name, 24)}</option>"
      end
    end
    return opts
  end
  
  # Via Coda Hale:
  #   http://blog.codahale.com/2006/01/14/a-rails-howto-simplify-in-place-editing-with-scriptaculous/
  def editable_content(options)
    puts options[:url].inspect
    options[:content] = { :element => 'span' }.merge(options[:content])
    options[:url] = {}.merge(options[:url])
    options[:ajax] = { :okText => "'ok'", :cancelText => "'cancel'"}.merge(options[:ajax] || {})
    
    url = url_for(options[:url])
    # For some reason url_for is creating URLs with "&amp;" in them.  Strip these out.
    url.gsub!('&amp;', '&')
    
    script = Array.new
    script << "new Ajax.InPlaceEditor("
    script << "  '#{options[:content][:options][:id]}',"
    script << "  '#{url}',"
    script << "  {"
    script << options[:ajax].map{ |key, value| "#{key.to_s}: #{value}" }.join(", ")
    script << "  }"
    script << ")"

    content_tag(
     options[:content][:element],
     options[:content][:text],
     options[:content][:options]
    ) + javascript_tag( script.join("\n") )
  end

end
