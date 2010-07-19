# From http://blog.seagul.co.uk/articles/2006/10/20/boolean-method-in-ruby-sibling-of-array-float-integer-and-string
module Kernel
  def Boolean(string)
    return true if string == true || string =~ /^true$/i
    return false if string == false || string.nil? || string =~ /^false$/i
    return false
    #raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
  end
end

class Object
  def to_bool
    Boolean(self)
  end
end