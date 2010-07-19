class CreateOauthSites < ActiveRecord::Migration
  def self.up
    create_table :oauth_sites do |t|
      t.timestamps

      t.string :name, :null=>false
      t.string :url, :null=>false
      t.string :consumer_key
      t.string :consumer_secret
      t.text :request_url
      t.text :access_url
      t.text :authorize_url
    end

    add_index :oauth_sites, :name
  end

  def self.down
    drop_table :oauth_sites
  end
end
