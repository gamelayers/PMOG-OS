class PmogClassesToAssociations < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE users CHANGE primary_class primary_association varchar(255) default NULL;"
    execute "ALTER TABLE users CHANGE secondary_class secondary_association varchar(255) default NULL;"
    execute "ALTER TABLE users CHANGE tertiary_class tertiary_association varchar(255) default NULL;"
  end

  def self.down
    execute "ALTER TABLE users CHANGE primary_association primary_class varchar(255) default NULL;"
    execute "ALTER TABLE users CHANGE secondary_association secondary_class varchar(255) default NULL;"
    execute "ALTER TABLE users CHANGE tertiary_association tertiary_class varchar(255) default NULL;"
  end
end
