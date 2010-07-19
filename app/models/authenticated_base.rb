# Base authenticated class.  Inherit from this class, don't put any app-specific code in here.
# That way we can update this model if auth_generators update.

require 'digest/sha1'
module AuthenticatedBase
  def self.included(base)

    base.set_table_name base.name.tableize

    #base.validates_presence_of     :login, :email
    base.validates_presence_of     :login
    base.validates_presence_of     :password,                   :if => :password_required?
    #base.validates_presence_of     :password_confirmation,      :if => :password_required?
    base.validates_length_of       :password, :within => 4..40, :if => :password_required?
    base.validates_confirmation_of :password,                   :if => :password_required?
    base.validates_length_of       :login,    :within => 3..40
    #base.validates_length_of       :email,    :within => 3..100
    base.before_save :encrypt_password

    base.cattr_accessor :current_user

    base.extend ClassMethods
  end

  attr_accessor :password

  module ClassMethods

    ## Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
    def authenticate(login, password)
      u = User.find( :first, :conditions => { :login => login.to_s }) # need to get the salt
      u && u.authenticated?(password.to_s) ? u : nil
    end

    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end

  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  # Useful place to put the login methods
  def remember_me_until(time)
    self.visits_count = visits_count.to_i + 1
    self.last_login_at = Time.now
    self.remember_token_expires_at = time
    self.remember_token = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    (crypted_password.blank? || !password.blank?)
  end
end
