# Author:: Brendan G. Lim (brendangl@gmail.com)

module ActsAsTinyURL

  class ActsAsTinyURLError < StandardError; end;    

  def tiny_url(uri, options = {}) 
    defaults = { :validate_uri => false }
    options = defaults.merge options
    return validate_uri(uri) if options[:validate_uri]
    return generate_uri(uri)
  end 

  private
  
  def validate_uri(uri)
    confirmed_uri = uri[/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix]
    if confirmed_uri.blank?
      return false
    else
      return true
    end
  end
  
  def generate_uri(uri)
    confirmed_uri = uri[/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix]
    if !confirmed_uri.blank?
      escaped_uri = URI.escape("http://tinyurl.com/api-create.php?url=#{confirmed_uri}")
      uri_parsed = Net::HTTP.get_response(URI.parse(escaped_uri)).body
      return uri_parsed
    else
      raise ActsAsTinyURLError.new("Provided URL is incorrectly formatted.")
    end
  end
  
end