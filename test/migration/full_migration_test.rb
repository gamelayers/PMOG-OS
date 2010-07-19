# From http://spin.atomicobject.com/2007/02/27/migration-testing-in-rails/
# Runs as part of rake, and can be run by hand - `rake test:migrations`

require File.expand_path(File.dirname(__FILE__) + '/../test_helper') 

#
# This excercises the full set of migrations for your Rails app.
# It proves:
#   - After full migration, the database is in the expected state, including:
#     - All table structure
#     - Default data (if any)
#   - Full downward (version 0) migration functions correctly.
#
# YOU NEED TO:
#   - Update "see_full_schema"
#   - Update "see_data"
# 
class FullMigrationTest < ActionController::IntegrationTest

  # 
  # Transactional fixtures can, on occasion, cause migration tests to hang.
  # Applying this setting here will turn transactional fixtures off for THIS
  # SUITE ONLY
  #
  # self.use_transactional_fixtures = false

  def conn
    ActiveRecord::Base.connection
  end

  def see_empty_schema
    assert_schema do |s|
      # is nothing 
    end
  end

  #
  # Structure and Content assertions
  #

  # Fully assert db structure after full migration
  def see_full_schema
    assert_table :users do |t|
      t.column :id, :string, :limit => 36
      t.column :login, :string, :limit => 20
      t.column :email, :string, :limit => 40
      t.column :crypted_password, :string, :limit => 40
      t.column :salt, :string, :limit => 40
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :last_login_at, :datetime
      t.column :remember_token, :string, :limit => 40
      t.column :remember_token_expires_at, :datetime
      t.column :visits_count, :integer, :limit => 11
      t.column :time_zone, :string
      t.column :identity_url, :string
      t.column :forename, :string
      t.column :surname, :string
      t.column :url, :string
      t.column :date_of_birth, :date
      t.column :gender, :string, :limit => 1
      t.column :country, :string
      t.column :datapoints, :integer, :limit => 7
      t.column :total_datapoints, :integer, :limit => 11
      t.column :beta_key_id, :integer, :limit => 11
      t.column :motto, :string
      t.column :privacy_level, :string
      t.column :posts_count, :integer, :limit => 11
      t.column :average_rating, :integer, :limit => 1
      t.column :total_ratings, :integer, :limit => 5
      t.column :lifetime_pings, :integer, :limit => 11
      t.column :available_pings, :integer, :limit => 7
      t.column :ratings_count, :integer, :limit => 5
      t.column :remote_ip, :string
      t.column :last_login_attempt, :datetime
      t.column :failed_login_attempts, :integer, :default => 0, :limit => 2
      t.column :locked, :boolean, :default => false
      t.column :welcomed, :boolean, :default => nil
      
      # Indexes
      t.index :beta_key_id, :name => 'index_users_on_beta_key_id'
      t.index :email, :name => 'index_users_on_email'
      t.index :last_login_at, :name => 'index_users_on_last_login_at'
      t.index :login, :name => 'index_users_on_login'
      t.index :remember_token, :name => 'index_users_on_remember_token'
      t.index :updated_at, :name => 'index_users_on_updated_at'
    end

    assert_table :motd do |t|
      t.column :id, :string, :limit => 36
      t.column :title, :string, :limit => 255
      t.column :body, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      
      t.index :created_at, :name => 'index_motd_on_created_at'
    end

    # TODO: add assertions here to verify your schema was built    
    #
    # Something like this can be used to see the entire schema
    # is as expeted.
    #
    # assert_schema do |s|
    #   s.table :cat_tails do |t|
    #     t.column :id,    :integer
    #     t.column :name,  :string
    #   end
    #
    #   s.table :dogs do |t|
    #     t.column :id,    :integer
    #     t.column :name,  :string
    #   end
    # end

    #
    # Alternatively individual tables can be checked.
    #
    # assert_table :cats_tails do |s|
    #   t.column :id,    :integer
    #   t.column :name,  :string
    # end
  end

  # Make sure data you expect your migrations to load are in there:
  def see_default_data
    @user = User.find_by_login 'suttree'
    @pmog_user = User.find_by_email 'self@pmog.com'

    assert @user
    assert @user.has_role?('site_admin')

    assert @pmog_user
    assert ! @pmog_user.has_role?('site_admin')
    
    assert_equal 9, Tool.count
    assert_equal 9, PmogClass.count
  end

  #
  # TESTS
  #

  def test_full_migration
    drop_all_tables
    
    see_empty_schema

    migrate

    see_full_schema

    see_default_data

    # For some reason rake test:migrations leaves a folder
    # called 'index' with some other empty folders inside, so let's
    # tidy that up here. Of course, this is somewhat scary and dangerous
    # code, so, um, beware! Disabled for now, but we can enable this if required
    #FileUtils.rm_r "#{RAILS_ROOT}/index"
  end

end
