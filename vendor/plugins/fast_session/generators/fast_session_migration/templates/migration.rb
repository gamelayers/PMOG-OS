class <%= class_name %> < ActiveRecord::Migration
  CGI::Session::ActiveRecordStore::FastSessions.table_name = "<%= session_table_name %>"

  # If you're going to use this module with MySQL 5.1.22+, then you'd 
  # like to set this to +true+ because it will provide you with consecutive
  # data inserts in InnoDB. Another cases when you'd like to use it is when
  # your MySQL server is I/O bound now and you do not want to add random I/O
  # because of randomized primary key.
  CGI::Session::ActiveRecordStore::FastSessions.use_auto_increment = false

  def self.up
    say "Creating sessions table..."
    CGI::Session::ActiveRecordStore::FastSessions.create_table!
  end

  def self.down
    say "Destroying sessions table..."
    CGI::Session::ActiveRecordStore::FastSessions.drop_table!
  end
end
