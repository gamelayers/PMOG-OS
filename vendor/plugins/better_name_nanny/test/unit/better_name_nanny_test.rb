require 'test/unit'
# Add your module file here
require File.dirname(__FILE__) + '/../../lib/better_name_nanny'

class BetterNameNannyTest < Test::Unit::TestCase
  include BetterNameNanny

  def setup
    @good_words = (IO.readlines File.join(File.dirname(__FILE__), 'test_good_words.txt')).each { |w| w.chop! }
    @bad_words = (IO.readlines File.join(File.dirname(__FILE__), 'test_bad_words.txt')).each { |w| w.chop! }
  end

  def test_bad_words
    @bad_words.each { |x|
      #puts "Bad Testing #{x}"
      assert bad_name?(x)
    }
  end

  def test_good_words
    @good_words.each { |x|
      #puts "Good Testing #{x}"
      assert !bad_name?(x)
    }
  end

end
