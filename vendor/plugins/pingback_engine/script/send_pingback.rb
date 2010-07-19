#!/usr/bin/ruby

require "xmlrpc/client"
 
server = XMLRPC::Client.new2("http://localhost:3000/pingback/xml")

ok, param = server.call2("pingback.ping", ARGV[0], ARGV[1])

if ok then
  puts "Response: #{param}"
else
  puts "Error:"
  puts param.faultCode 
  puts param.faultString
end
