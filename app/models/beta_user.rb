# == Schema Information
# Schema version: 20081220201004
#
# Table name: beta_users
#
#  id          :integer(11)   not null, primary key
#  email       :string(255)   
#  emailed     :integer(11)   default(0)
#  created_at  :datetime      
#  beta_key_id :integer(11)   
#

class BetaUser < ActiveRecord::Base
  belongs_to :beta_key, :dependent => :destroy

  acts_as_cached
  after_save :expire_memcache

  validates_uniqueness_of :email
  validates_format_of :email, :with => /^\S+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,4}|[0-9]{1,4})(\]?)$/ix

  # Cached finder for the admin page, mostly
  def self.cached_find_all
    get_cache( "all" ) { 
      find( :all, :include => { :beta_key => :user } )
    }
  end

  def self.count_invited
    count( :all, :conditions => "beta_key_id IS NOT NULL" )
  end
  
  def self.count_uninvited
    count( :all, :conditions => "beta_key_id IS NULL" )
  end

  def self.count_signed_up
    User.count( :all, :conditions => "beta_key_id IS NOT NULL" )
  end

  # Send an invite from a registered PMOG user
  def self.email_invite(current_user, params)
    # Is this user already playing PMOG?
    raise Message::RecipientAlreadyPlaying if User.find_by_email(params[:recipient])
    
    # No, the player is not already playing.
    beta_user = BetaUser.find_by_email(params[:recipient])
    
    # If this user already exists in the beta list, just invite them
    if beta_user
      # Just tell the user they have invited someone, but don't send the
      # email if it's already been sent.
      beta_user.email_beta_key(current_user, params) unless beta_user.emailed == 1
      return true
    elsif beta_user.nil?
      # Try to create them
      beta_user = BetaUser.create( :email => params[:recipient] )

      if beta_user.valid?
        beta_user.email_beta_key(current_user, params)
        return true
      else
        return false
      end
    end
  end

  # Email a beta key to a user who has signed up on our waiting list
  def email_beta_key(current_user, params)
    b = BetaKey.find( :first, :conditions => { :emailed => 0, :user_id => current_user.id } )
    b = current_user.beta_keys.create if b.nil?

    return false if b.nil?
    return false if self.emailed == 1

    Mailer.deliver_email_invite(
      :subject => "#{current_user.login} has invited you to join The Nethernet",
      :recipients => params[:recipient],
      :body => { 
                  :email => params[:recipient],
                  :inviter => current_user,
                  :message => params[:message],
                  :key => b.key,
                }
    )
    
    # Keep track of the keys used for this user
    self.beta_key_id = b.id
    self.emailed = 1
    b.emailed = 1
    self.save
    b.save
  end

  # Re-send the beta email if the user reports they haven't received it
  # Note that we don't need to save anything here, just grab the previously
  # used beta key and create the email again.
  def email_beta_key_again(sender)
    b = self.beta_key

    Mailer.deliver_beta_key(
      :subject => "The Nethernet Signup",
      :recipients => email,
      :body => { 
                  :email => email,
                  :key => b.key,
                  :inviter => sender
                }
    )
  end
  
  protected
  def expire_memcache
    BetaUser.expire_cache( "all" )
  end
end
