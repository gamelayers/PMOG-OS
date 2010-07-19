class Tld < ActiveRecord::Base
  belongs_to :user # constantly changing!

  def increment(user=nil, ip=nil) # this doesn't have to be exact, it's for stats
    self.total = self.total == nil ? 1 : self.total + 1
    self.last_ip = nil ? nil : ip.strip
    self.user = user
    self.save
  end

  def self.safe_add(url)

    name = self.get_tld(url)
    begin
      return Tld.find_or_create_by_name(name)

    rescue => e
      return Tld.find_by_name(name) if (e.message.downcase =~ /duplicate entry/)  != nil   # already exists, no biggie, string match sucks, is there a better way?

      raise # other stuff just gets reraised
    end

  end

  protected

  def self.get_tld(url="unknown.unk")
    #puts "URL: #{url}"
    url = "http://" + url if url['://'] == nil

    host = URI.parse(url).host if url[':'] != nil
    host = host[4,host.length] if host =~ /^www\./

    return url ? host.nil? : host
  end

end
