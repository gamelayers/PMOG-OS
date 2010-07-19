class CreateOauthCredentials < ActiveRecord::Migration
  def self.up
    create_table :oauth_credentials do |t|
      t.timestamps
      t.integer :oauth_site_id
      t.integer :user_id
      t.string :remote_login
      t.string :access_token
      t.string :access_secret
    end

    add_index :oauth_credentials, [:remote_login, :oauth_site_id]
  end

  def self.down
    drop_table :oauth_credentials
  end
end
