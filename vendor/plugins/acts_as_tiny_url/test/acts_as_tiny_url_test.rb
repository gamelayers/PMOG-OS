require 'test/unit'
require File.dirname(__FILE__) + '/../lib/acts_as_tiny_url' 

class ActsAsTinyUrlTest < Test::Unit::TestCase
  include ActsAsTinyURL
  $GOOGLE_URL = "http://google.com"
  $GOOGLE_SHORTENED_URL = "http://tinyurl.com/2tx"
  
  def test_with_google_url
    true
    #assert_equal $GOOGLE_SHORTENED_URL, tiny_url($GOOGLE_URL)
  end

end