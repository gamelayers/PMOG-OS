# I'm sick of crappy html around the site, so let's at least
# left-align it and strip out all the useless whitespace in an 
# attempt to speed up page loads - duncan 19/02/09
class OutputCompressionFilter
  def self.filter(controller)
    controller.response.body = controller.response.body.gsub(/^\s+/, '').gsub(/\s+$/, $/)
  end
end