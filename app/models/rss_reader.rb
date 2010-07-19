require 'rss/2.0'
require 'open-uri'

class RssReader

  acts_as_cached

  # Gets the first posts from the main news.thenethernet.com feed
  def self.get_pmog_news
    get_cache('home_news_feed', :ttl => 1.day) do
      get_first_post('http://news.thenethernet.com/feed/')
    end
  end
  
  # Gets +limit+ posts from the feed of posts
  def self.get_pmog_news_stream(limit = 3)
    get_cache("home_news_stream_#{limit}", :ttl => 1.day) do
      get_posts("http://news.thenethernet.com/category/content/feed/", limit)
    end
  end

  # Gets +limit+ posts from the feed of posts tagged with +tag+
  def self.get_pmog_news_by_tag(tag, limit = 5)
    get_cache("tagged_news_feed_#{tag}", :ttl => 1.day) do
      get_posts("http://news.thenethernet.com/tag/#{tag}/feed/")
    end
  end
  
  # Gets the first post from the special happenings feed
  def self.get_special_happenings
    get_cache('special_happenings_feed', :ttl => 1.day) do
      get_first_post('http://news.thenethernet.com/category/special-happenings/feed/')
    end
  end

  # Returns from first post from +feed+
  def self.get_first_post(feed)
    active_post = parse_feed(feed).first

    # clean off the dead ellipsis on the end
    active_post.description = active_post.description[0..132]
    return active_post
  end
  
  # Returns +limit+ posts from the +feed+
  def self.get_posts(feed, limit = 5)
    limit = limit - 1 # off by one
    posts = parse_feed(feed, limit)[0..limit]
    limit.times do |i|
    	next if posts[i].nil?
      posts[i].description = posts[i].description[0..132]
    end
    posts
  end
  
  # Returns an array of posts from +feed_url+. If news.pmog.com is down
  # it returns a special post so that we don't fall over when Site5 goes down.
  def self.parse_feed(feed_url, length=1, perform_validation=false)
    begin
      posts = []
      open(feed_url) do |rss|
        posts = RSS::Parser.parse(rss, perform_validation).items
      end
      posts[0..length - 1] if posts.size > length
    rescue
      [OpenStruct.new(:link => '', :title => 'The Nethernet News is Unavailable', :description => 'There is a problem retrieving the latest Nethernet news')]
    end
  end
end
