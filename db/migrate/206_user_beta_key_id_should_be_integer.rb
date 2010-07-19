class UserBetaKeyIdShouldBeInteger < ActiveRecord::Migration
  # The users.beta_key_id column should be an integer, rather than a string.
  # Having it as a string when it should be an integer causes the index to be ignored.
  # Explanantion of why this is, from Max at EY:
  #
  # The reason this does not use the index is because the 4979 is an integer so MySQL has
  # to convert the column values from strings to integers. The implicit conversion is just 
  # like wrapping a CAST function call around the column. Function calls around columns 
  # prevent indexes from being used.
  def self.up
    execute "ALTER TABLE users CHANGE beta_key_id beta_key_id int(11) default NULL"
  end

  def self.down
    execute "ALTER TABLE users CHANGE beta_key_id beta_key_id varchar(10) default NULL"
  end
end
