require File.dirname(__FILE__) + '/../test_helper'

class BooleanTest < Test::Unit::TestCase

  def test_should_return_true
    assert_equal true, Boolean('true')
    assert_equal true, Boolean('TrUe')
    assert_equal true, Boolean(true)
    assert_equal true, 'true'.to_bool
    assert_equal true, 'tRue'.to_bool
    assert_equal true, true.to_bool
  end

  def test_should_return_false
    assert_equal false, Boolean(nil)
    assert_equal false, Boolean('false')
    assert_equal false, Boolean('FaLsE')
    assert_equal false, Boolean(false)
    assert_equal false, nil.to_bool
    assert_equal false, 'false'.to_bool
    assert_equal false, 'fAlSe'.to_bool
    assert_equal false, false.to_bool
  end

  def test_should_default_to_false
    assert_equal false, Boolean('true ')
    assert_equal false, Boolean(' true')
    assert_equal false, Boolean(' true ')
    assert_equal false, Boolean('false ')
    assert_equal false, Boolean(' false')
    assert_equal false, Boolean(' false ')
    assert_equal false, Boolean('BLAH')
    assert_equal false, Boolean(1)
    assert_equal false, Object.new.to_bool
  end
end