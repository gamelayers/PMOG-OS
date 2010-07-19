# Copyright (c) 2006 Sébastien Gruhier (http://xilinus.com, http://itseb.com)
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# VERSION 0.25
module CarouselHelper
  def carousel(id, options={}, init_on_load = true, &block)        
    ul  = content_tag "ul", (block_given? ? yield : ""), :class => "carousel-list"
    clip  = content_tag "div", ul, :class => "carousel-clip-region"
    content_tag "div", clip, :id => id, :class => "carousel-component"
    
    jid = id.gsub(/-/, "_")
    logger.warn options.inspect
    var_name = options[:var_name] ? options.delete(:var_name) : "var carousel"
    js = "function initCarousel_#{jid}() {#{var_name} = new Carousel('#{id}', #{options_for_javascript(options)})};"
    js += init_on_load ? "Event.observe(window, 'load', initCarousel_#{jid});" : "initCarousel_#{jid}()"
    
    content_tag("div", clip, :id => id, :class => "carousel-component") + javascript_tag(js)
  end

  private
  ## Extend options_for_javascript to handle hashmap of hashmap
  def options_for_javascript(options)
    '{' + options.map {|k, v|  v.kind_of?(Hash) ? "#{k}:#{options_for_javascript(v)}" : "#{k}:#{v}"}.sort.join(', ') + '}'
  end
end