class OauthCredential < ActiveRecord::Base
  belongs_to :user
  belongs_to :oauth_site
  validates_presence_of :user
  validates_presence_of :oauth_site

  def self.get_credentials(oauth_site, remote_login)
    val = OauthCredential.find(:first, :conditions => ["remote_login = ? and oauth_site_id = ?", remote_login, oauth_site.id])
    return val
  end

  def self.new_credential(oauth_site, remote_login, access_token, user)
        #puts "#{user.to_yaml}"
        OauthCredential.create(:oauth_site => oauth_site,
                                :remote_login => remote_login,
                                :access_token => access_token.token,
                                :access_secret => access_token.secret,
                                :user => user)
  end

  
end
