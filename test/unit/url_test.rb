require File.dirname(__FILE__) + '/../test_helper'

# Testing out our Url normalisations
class UrlTest < Test::Unit::TestCase
  def setup
    super
  end

  def test_unsupported_formats
    image_url = "http://www.suttree.com/favicon.ico"
    text_url = "http://www.suttree.com/about"
    file_url = "file://C:\Windows\Desktop"
    assert ! Url.unsupported_format?(image_url)
    assert ! Url.unsupported_format?(text_url)
    assert Url.unsupported_format?(file_url)
  end

  def test_normalise
    [ "http://www.suttree.com/", "www.suttree.com" ].each do |url|
      assert_equal "http://www.suttree.com", Url.normalise(url)
    end
    
    [ "http://suttree.com/", "suttree.com"].each do |url|
      assert_equal "http://suttree.com", Url.normalise(url)
    end
    
    # No ips, nor https
    [ "https://www.securebankingonline.com", "158.152.1.58", "http://0.0.0.0:3000", nil, "" ].each do |url|
      assert_equal false, Url.normalise(url)
    end
  end
  
  def test_extract_and_normalise_from_env
    tracked_url = "version=0.408&url=http://www.suttree.com&host=suttree.com"
    assert_equal "http://www.suttree.com", Url.extract_and_normalise_from_env(tracked_url, "0.408")
    assert_equal "http://www.suttree.com", Url.extract_and_normalise_from_env(tracked_url, "0.417")

    [ nil, "https://www.google.com", "158.152.1.43" ].each do |url|
      assert_equal false, Url.extract_and_normalise_from_env(url, "0.408")
      assert_equal false, Url.extract_and_normalise_from_env(url, "0.417")
    end
  end
  
  def test_host
    [ "pmog.com/users/suttree/", "pmog.com", "http://pmog.com" ].each do |url|
      assert_equal "pmog.com", Url.host(url)
    end
    
    [ nil, "https://www.google.com", "158.152.1.43" ].each do |url|
      assert_equal false, Url.host(url)
    end
  end
  
  def test_domain
    [ "news.bbc.co.uk", "http://bbc.co.uk/uk/sport", "my.bbc.co.uk/path/to/file/"].each do |url|
      assert_equal "bbc.co.uk", Url.domain(url)
    end
    
    [ nil, "158.152.1.58" ].each do |url|
      assert_equal false, Url.domain(url)
    end
  end
  
  def test_tld
    [ "suttree.com", "www.suttree.com" ].each do |url|
      assert_equal "com", Url.tld( Url.domain(url) )
    end
    
    assert_equal false, Url.tld("http://www.suttree.com")
  end
  
  def test_sub_domain
    [ "en.pmog.com", "en.wikipedia.org", "en.suttree.com" ].each do |url|
      assert_equal "en", Url.sub_domain(url)
    end
  end
  
  def test_variants
    url = "http://google.com"

    # frigid
    assert_include "http://www.google.com", Url.variants(url)
    
    # promiscuous
    assert_include "http://www.google.com", Url.variants(url, true)
    assert_include "http://www.google.co.uk", Url.variants(url, true)
    assert_include "http://google.co.uk", Url.variants(url, true)
    
    # error handling
    assert_equal [], Url.variants('https://www.google.com', true)
    assert_equal [], Url.variants('158.152.1.58', false)
    assert_equal [], Url.variants(nil, true)
  end
  
  def test_variant_matches
    # frigid
    assert Url.variant_matches( "pmog.com/users/suttree", "www.pmog.com/users/suttree" )
    assert Url.variant_matches( "www2.flickr.com/photos/suttree1975", "flickr.com/photos/suttree1975" )
    assert ! Url.variant_matches( "bbc.com", "www.bbc.co.uk" )
    assert ! Url.variant_matches( "www.flickr.co.uk", "flickr.com" )
    assert ! Url.variant_matches( "dev.suttree.com", "www.suttree.com" )

    # promiscuous
    assert Url.variant_matches( "google.com", "www.google.co.uk", true )
    assert Url.variant_matches( "www.google.co.uk", "google.com", true )
    assert Url.variant_matches( "en.wikipedia.org", "www.wikipedia.org", true )
    assert Url.variant_matches( "usc.facebook.com", "www.facebook.com", true )
    assert Url.variant_matches( "usc.facebook.com/path/to/file", "www.facebook.com/path/to/file", true )
  end
  
  def test_first_match
    urls = [ "http://www.suttree.com", "http://www.bbc.co.uk", "http://www.google.com" ]

    # frigid
    assert_equal "http://www.google.com", Url.first_match( "http://www.google.com", urls )
    assert_equal "http://www.bbc.co.uk", Url.first_match( "http://www.bbc.co.uk", urls )
    
    # promiscuous
    assert_equal "http://www.google.com", Url.first_match( "http://www.google.co.uk", urls, true )
    assert_equal "http://www.bbc.co.uk", Url.first_match( "http://news.bbc.co.uk", urls, true )
  end
end
