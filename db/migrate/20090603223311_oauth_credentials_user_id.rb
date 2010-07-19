class OauthCredentialsUserId < ActiveRecord::Migration
  def self.up
    remove_column :oauth_credentials, :user_id
    add_column :oauth_credentials, :user_id, :string, :limite =>36
    add_index :oauth_credentials, [ :user_id, :created_at ]
  end

  def self.down
    remove_index :oauth_credentials, [ :user_id, :created_at ]
  end
end
