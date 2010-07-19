#!/usr/bin/env ruby

# Deprecated - since we use User.all which is much faster. We'll keep 
# this script just in case it needs finishing off, further down the line


# Awarding badges without ActiveRecord for a smaller memory footprint
# This is just the bare bones. If we want to pursue this idea we can
# move the code from Badge.rb into here. We should also use a pid file 
# too, so that the script only runs when no other instance is running.

require 'rubygems'
require "mysql"

# Ensure the environment was specified
if ARGV.length != 1
  puts "usage: ruby runner.rb <rails_env>" 
  exit 1
end

# Fetch connection details from database.yml
conf = YAML::load(File.open(File.dirname(__FILE__) + '/../../config/database.yml'))
hostname = conf[ARGV.first]["host"]
username = conf[ARGV.first]["username"]
password = conf[ARGV.first]["password"]
database = conf[ARGV.first]["database"]

# Connect to MySQL and return a MySQL Object
my= Mysql.new(hostname, username, password, database)

# Prepare the statement
st= my.prepare("SELECT VERSION()")

# Execute the statement
st.execute

# Get the result set
result= st.fetch

# Print out the result
puts result.to_s
