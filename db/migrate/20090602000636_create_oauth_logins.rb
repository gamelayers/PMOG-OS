class CreateOauthLogins < ActiveRecord::Migration
  def self.up
    create_table :oauth_logins do |t|
      t.timestamps

      t.integer :oauth_site_id, :null=>false
      t.string :screen_name, :null=>false
      t.string :token
      t.string :secret
    end

    add_index :oauth_logins, [:screen_name, :token, :secret]
    add_index :oauth_logins, [:created_at]
  end

  def self.down
    drop_table :oauth_logins
  end
end
