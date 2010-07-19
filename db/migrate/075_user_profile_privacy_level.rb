class UserProfilePrivacyLevel < ActiveRecord::Migration
  def self.up
    add_column :users, :privacy_level, :string, :default => "public"
  end

  def self.down
    remove_column :users, :privacy_level
  end
end