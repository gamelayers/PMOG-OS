require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

class PingbackTest < ActiveSupport::TestCase
  
  def setup
    Pingback.excerpt_length = 10
    Pingback.save_callback = nil
  end
  
  def test_title_where_title_exists
    content = "<html><title>My linking title</title></html>"
    pb = Pingback.new(content, "target")
    pb.ping
    assert_equal "My linking title", pb.title
  end
  
  def test_title_where_title_is_missing
    content = "<html><no_title>My linking title</no_title></html>"
    pb = Pingback.new(content, "target")
    pb.ping
    assert_equal false, pb.title
  end
  
  def test_find_linking_node_where_link_exists
    content = '<html>This is really <a href="http://target.com/target/link">awesome</a>, since this plugin kicks ass.</html>'
    pb = Pingback.new(content, "http://target.com/target/link")
    pb.ping
    assert_kind_of Hpricot::Elem, pb.linking_node
  end
  
  def test_find_linking_node_where_link_is_missing
    content = "<html><no_title>My linking title</no_title></html>"
    pb = Pingback.new(content, "target")
    pb.ping
    assert ! pb.linking_node
  end
  
  def test_excerpt_content_to
    content = '<html>This is really <a href="http://target.com/target/link">awesome</a>, since this plugin kicks ass.</html>'
    pb = Pingback.new(content, "http://target.com/target/link")
    pb.ping
    assert_equal 'is really <a href="http://target.com/target/link">awesome</a>, since th', pb.excerpt
  end
  
  ### TODO: implement!
  def test_excerpt_content_to_with_not_enough_text
    content = '<html>This is really <a href="http://target.com/target/link">awesome</a>, since this plugin kicks ass.</html>'
    Pingback.excerpt_length = 80
    pb = Pingback.new(content, "http://target.com/target/link")
    pb.ping
    assert_equal 'This is really <a href="http://target.com/target/link">awesome</a>, since this plugin kicks ass.', pb.excerpt
  end
  
  ### TODO: implement!
  def test_excerpt_content_to_with_enough_but_nested_text
    content = '<html>This is really <a href="http://target.com/target/link">awesome</a>, since this plugin kicks ass.</html>'
    Pingback.excerpt_length = 80
    pb = Pingback.new(content, "http://target.com/target/link")
    pb.ping
    assert_equal 'This is really <a href="http://target.com/target/link">awesome</a>, since this plugin kicks ass.', pb.excerpt
  end
  
  
  def test_receive_ping_with_invalid_source_url
    pb = Pingback.new("http://invalid", "http://target.com/target/link")
    assert_equal 16, pb.ping
  end
  
  def test_save_callback
    pb = Pingback.new("a target uri", nil)
    Pingback.save_callback do |ping|
      ping.source_uri
    end
    
    assert_equal "a target uri", pb.save_pingback
  end
  
  # test helpers ----------------------------------------------------------------
  def test_set_xpingback_header
    assert false
  end
  
  def test_pingback_link_tag
    assert false
  end
  
  # test controller -------------------------------------------------------------
  def test_controller_return_codes
    # provoke errors and compare return codes/exceptions.
    assert false
  end
end
