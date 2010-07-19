class PmogUsersBetaKey < ActiveRecord::Migration
  def self.up
    pmog_user = User.find_by_email( 'self@pmog.com' )
    execute( "UPDATE beta_keys SET user_id = '#{pmog_user.id}'")
  end

  def self.down
    execute( "UPDATE beta_keys SET user_id = null" )
  end
end
