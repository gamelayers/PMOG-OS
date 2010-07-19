class TwitterOauth < ActiveRecord::Migration
  def self.up
    request_url = "http://twitter.com/oauth/request_token"
     access_url = "http://twitter.com/oauth/access_token"
  authorize_url = "http://twitter.com/oauth/authorize"
            url = "http://www.twitter.com"

    OauthSite.create(:name => "twitter_development",
			:consumer_key => "t0iiK4CZowbfEQninMdZog",
			:consumer_secret => "foKW8PClDG5l3iUzq9uvyfIYGBjQvY8vtP4LHBzyHkw",
			:request_url => request_url,
			:access_url => access_url,
			:authorize_url => authorize_url,
			:url => url)

    OauthSite.create(:name => "twitter_staging",
			:consumer_key => "9NM57DqKFpX5lJRfr0J6Aw",
			:consumer_secret => "8idREEX2GnBVU2ndHDT5GTz7wXxlPdMpbcFjX1hqeU",
			:request_url => request_url,
			:access_url => access_url,
			:authorize_url => authorize_url,
			:url => url)

    OauthSite.create(:name => "twitter",
			:consumer_key => "jIZ6i5xPrm4N62BIWpT7Nw",
			:consumer_secret => "pobPXyueILrWuTBjP6t1WS8QVoahVsvHVMz31tMmC4",
			:request_url => request_url,
			:access_url => access_url,
			:authorize_url => authorize_url,
			:url => url)
  end

  def self.down
    execute "delete from oauth_sites where name like 'twitter%'"
  end
end
