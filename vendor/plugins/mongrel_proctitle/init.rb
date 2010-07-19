# Using this plugin is very helpful, however it creates mongrels that are unkillable,
# meaning that subsequent deploys don't get access to the new codebase. If you
# use this plugin, make sure to 'sudo killall mongrel_rails' once you're done with it - duncan 02/02/2009
# 
# Really, trust me, don't enable this plugin as it'll bring the site to its' knees - duncan 02/03/09
#
# From EY: Yes, unfortunately the cool bits of the proctitle plugin interfere with the monit_mongrel startup script. 
# If that functionality is something you absolutely need to employ, let us know by opening a ticket and we can modify 
# the script to work with the new proctitle. I'll go ahead and close this ticket out for now.

#if defined?(Mongrel)
#  require "mongrel_proctitle"
#end
