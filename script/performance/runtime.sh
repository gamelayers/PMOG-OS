#! /bin/sh

# From http://www.dcmanges.com/blog/rails-performance-tuning-workflow
#
# This script repeatedly loads the home page and greps for the X-Runtime response.
# It'll run forever, so ctrl-c to get out of it. Replace the cookie value
# with your own from the Firefox cookie viewier - duncan 21/01/09
# Replace the cookie with your own session cookie
#
# You can also use clistat and grep for X-Runtime, like this:
# while true; do curl --silent --head --cookie "www_pmog_session_id=1234567890" http://pmog.com | grep X-Runtime; done | script/performance/clistat.rb 
while true; do curl --silent --head --cookie "www_pmog_session_id=1234567890" http://pmog.com | grep X-Runtime; done
