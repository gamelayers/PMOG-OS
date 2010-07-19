class LocationsKeysAndIndices < ActiveRecord::Migration
  # Altering the locations database table.
  # Note that this migration should only run on staging development
  # Since it has already run via the rake pmog:clear_locations task
  # 
  # Note that we add a prefix index on url, rather than on the whole thing, to save space
  # and also that we switch the index on id for a proper, unique primary key index
  def self.up
    if RAILS_ENV == 'development'
      execute 'drop index idx_locations_on_url on locations' rescue nil
      execute 'drop index index_locations_on_url_prefix on locations' rescue nil
      execute 'create index index_locations_on_url_prefix on locations(url(150))' rescue nil
      execute "ALTER TABLE locations ADD PRIMARY KEY(id)" rescue nil
      execute "ALTER TABLE locations DROP INDEX index_locations_on_id" rescue nil
    else
      puts "Refusing to migrate the locations database"
    end
  end

  def self.down
    if RAILS_ENV == 'development'
      #execute 'drop index index_locations_on_url_prefix on locations'
      #execute 'create index idx_locations_on_url on locations(url)'
      #execute 'create index index_locations_on_url_prefix on locations(url)'
      execute 'alter table locations add index index_locations_on_id(id)'
      execute 'alter table locations drop primary key'
    else
      puts "Refusing to migrate the locations database"
    end
  end
end
