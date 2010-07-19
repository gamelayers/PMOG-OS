require 'test_helper'

class TldTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true

    t1 = Tld.safe_add("http://www.google.com")
    assert t1 != nil
    t2 = Tld.safe_add("http://www.google.com")

    assert t1.id == t2.id

    t3 = Tld.safe_add("www.google.com")

    assert t3.id = t1.id

    t4 = Tld.safe_add("www.french.com")

    assert t4.id != t3.id
    
  end
end
