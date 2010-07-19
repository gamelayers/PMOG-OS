# The Name Nanny makes sure that users behave themselves when on the system.
# better version of name nanny, 5/2009 cwikla
#

module BetterNameNanny
  def self.regme(filename)

    path = File.join(File.dirname(__FILE__) , filename)
    regs = []
    IO.readlines(path).each { |w|
      w.strip!
      w = Regexp.new(w[1,w.length-2]) if w =~ /^\//
      #puts w
      regs << w
    }
    return regs.freeze
  end

  RESERVED_NAMES = regme("reserved_words.txt")
  BAD_WORDS = regme("bad_words.txt")

  # Use a non-descript error to prevent the users from trying to hack around the filter.
  # Hopefully, they will just give up and choose something nicer.

  def validates_cleanliness_of(*attr_names)
    configuration = { :message => "is unavailable" }
    configuration.merge!(attr_names.pop) if attr_names.last.is_a?(Hash)
    
    validates_each(attr_names) do |record, attr_names|
      record.errors.add( attr_names, configuration[:message] ) if is_unclean_name? record.send(attr_names)
      #puts record.errors
    end
  end

  def bleep_text(str)
    sub_text(str,"bleeep")
  end

  def smurf_text(str)
    sub_text(str,"smurf")
  end

  def strip_text(str)
    sub_text(str,"")
  end

  def self.is_unclean_name?(str)
    return true if str.nil?

    str = smush(str)
    RESERVED_NAMES.each { |x|
      #puts "Checking #{str} against #{x}"
      return true if x.class == String && str[x] != nil
      return true if x.class == Regexp && (str =~ x) != nil
    }
    BAD_WORDS.each { |x|
      #puts "Checking [#{str}] against [#{x}] <#{str[x]}> #{str.length} #{x.length}" if x.class == String
      #puts "Checking [#{str}] against [#{x}] " if x.class != String
      return true if x.class == String && str[x] != nil
      return true if x.class == Regexp && (str =~ x) != nil
    }
    return false
  end

  protected
  def sub_text(str,replacement = "bleeep")
    
    # Replace commas with an unlikely character combination
    str = str.gsub(',', ' ^&^ ')
    baddies = str.split(" ").map { | word | word.rstrip if BAD_WORDS.include?(word.rstrip.downcase) }.compact
    baddies.each { |word| str.gsub!(word, replacement) }
    
    # Return commas to their correct position within the string
    str = str.gsub(' ^&^ ', ',')
    str
  end

  def self.smush(word)
    # check the 733t, could be done with a loop and a dict, but this is more readable
    word = word.gsub(/0/, 'o')
    word = word.gsub(/1/, 'l')
    word = word.gsub(/2/, 'i')
    word = word.gsub(/3/, 'e')
    word = word.gsub(/4/, 'a')
    word = word.gsub(/5/, 's')
    word = word.gsub(/6/, 'g')
    word = word.gsub(/7/, 't')
    word = word.gsub(/8/, 'b')
    word = word.gsub(/9/, 'p')
    word = word.gsub(/[^A-Za-z]/, '')
    word = word.downcase
  end

  def is_unclean_name?(str)
    #puts "MY BAD NAME"
    val = BetterNameNanny::is_unclean_name?(str)
    return val
  end

end
