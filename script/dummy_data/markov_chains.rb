#  Markov Chain Generator
# based on the Python version by Gary Burd: http://gary.burd.info/2003/11/markov-chain-generator.html
# Released into the public domain, please keep this notice intact
# (c) InVisible GmbH    
# http://www.invisible.ch
# 

require "yaml"

class Array
  # return a random element of the array, similar to random.choice in python
  def choice
    self[ rand(self.size) ]
  end
end

class MarkovTool

  attr_accessor :markov_data

  def initialize( markov_data = nil )
    # use an unlikely combination for end of paragraph marker
    @nlnl = "#-#-"
    @markov_data = markov_data if markov_data.class == Hash
    @markov_data ||= Hash.new
  end

  def new_key( key, word)
    return @nlnl if word == "\n" 
    return key if !word
    return word
  end


  def markov_data_from_words( words )
    key = @nlnl
    words.each do | word |
      @markov_data[ key ] ||= Array.new
      @markov_data[ key ] << word
      key = new_key( key, word )
    end
  end

  def words_from_markov_data
    key = @nlnl
    result = Array.new
    word = ""
    # repeat until we hit a newline or a full-stop, remove the last clause to get     paragraphs, 
    while word && word != "\n" && word[-1] != "."[0]
      word = @markov_data[ key ].choice rescue nil
      key = new_key( key, word )
      result << word
    end
    result
  end

  # analyze and add a string
  def words_from_string( line )
    result = Array.new
    words = line.split
    if words.size > 0
      words.each { | word | result << word }
    else
      result << "\n"
    end
    result
  end

  # analyze and add a file
  def words_from_file( f )
    result = Array.new
    File.foreach( f ) do | line |
      result << self.words_from_string( line )
    end
    result.flatten
  end

  # build a paragraphs out of the result array
  def paragraph_from_words( words )
    result = Array.new
    words.each do | word |
      result << word
    end
    result.join( " " )
  end

  # return a complete paragraph
  def get_paragraph
    wo = self.words_from_markov_data

    self.paragraph_from_words( wo )
  end

  def store_in_yaml( f )
    YAML.dump( @markov_data, f )
  end

  def load_from_yaml( f )
    @markov_data = YAML.load( f )
  end

end

if __FILE__ == $0 then

  m = MarkovTool.new

  # read exisiting markov data
  File.open( File.dirname(__FILE__) + "/markov.yaml" ) { | yf | m.load_from_yaml( yf ) }

  #if ARGV[0]
  #  # if we got a filename, read it, process it and store the markov data
  #  w = m.words_from_file( ARGV[0] )
  #  m.markov_data_from_words( w )
  #  File.open( "markov.yaml", "w" ) { | yf | m.store_in_yaml( yf ) }
  #end

  # create a paragraph and display it
  p = m.get_paragraph
  puts p
end