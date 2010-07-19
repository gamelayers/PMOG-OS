#! /usr/bin/env ruby -w

# Copyright (c) 2008 GameLayers
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# README
#
# This is a simple script to walk a path over a website in a search for
# leaks. Or rather, as Evan Weaver put it in the Bleak House docs:
#
# The easiest way to fix a leak is to make it repeatable. First, write a script that 
# exercises your app in a deterministic way. Run it for a small number of loops; then 
# run bleak. Then run it for a larger number of loops, and run bleak again. The lines 
# that grow significantly between runs are your leaks for that codepath. Now, look at those 
# lines in the source and try to figure out what references them. Where do the return values 
# go? Add some breakpoints or output backtraces to STDERR as you go. Eventually you should 
# find a point where it is relatively clear that a reference is getting maintained. Try 
# to remove that reference, run your script again, and see if the object counts have dropped.
# http://blog.evanweaver.com/articles/2007/04/28/bleak_house/
#
# Note that there are several things you need to be aware of:
#
# i.   It won't work on straight dev.pmog.com because of the http auth setup,
#      use http://user:password@dev.pmog.com instead
#
# ii.  You'll need to grab your auth_token cookie from Firefox and then dump it
#      into cookies.txt if you want to test as a logged in user
#
# This could use a ton of improvements, but it'll do for now - duncan 20/06/08


# Setup some variables
paths_to_walk = [ '/', '/users/suttree', '/users/suttree/badges', '/acquaintances/suttree', '/missions', '/forums' ]

host = ARGV[0] || 'http://0.0.0.0:3000'
host = 'http://' + host unless host =~ /^http:\/\//
host.chop! if host[-1] == '/'

iterations = ARGV[1] || 2
growth = ARGV[2] || 2
max = ARGV[3] || 5

# The cookie auth token
cookie_file = File.expand_path(`pwd`.chomp + '/script/performance/bleak_house/cookies.txt')

# Start bleak house
system "RAILS_ENV=production BLEAK_HOUSE=1 ruby-bleak-house ./script/server &"

# Ok, let's go
puts "Walking #{host} #{iterations} times, growing by #{growth} iterations each time for a maximum of #{max} passes."
puts "\n"
sleep(1)

# Now walk the paths set out above, and gradually increase the number
# of times we  walk them, until we hit the limit. This should give
# us an idea of where the memory leaks are occurring.
max.times do |i|
  puts "Pass #{i+1}"
  iterations.times do |j|
    puts "\tAttempt #{j+1}"
    paths_to_walk.each do |path|
      puts "\t\tWalking #{host}#{path}"
      system "wget -S --load-cookies #{cookie_file} #{host}#{path} -q --spider"
    end

    # Stop the bleak server and run bleak house
    # Not sure how to do that, to be honest, or how to get
    # the name of the bleak dump file that sites in /tmp
    system "bleak /tmp/bleak.5979.0.dump > /tmp/bleak_walker_#{i+1}_#{j+1}.dump"
  end
  iterations += growth
end