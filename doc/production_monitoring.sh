= Production Monitoring =

You can use any of the scripts in config/shared_scripts to monitor the logs in production, just be sensible about it.

Alternatively, here are a few cheap tricks:

grep "(0 reqs/sec)" log/production.log | wc -l

grep -B 20  "(0 reqs/sec)" log/production.log | tail -n 100

# Show a list of actions sorted by total time taken
cat log/production.log | grep Completed | awk '{ print "[" $8 "] - " $0 }' | sort -nr

# And the same for rendering time taken
cat log/production.log | grep Completed | awk '{ print "[" $13 "] - " $0 }' | sort -nr

# Again or database time taken
cat log/production.log | grep Completed | awk '{ print "[" $17 "] - " $0 }' | sort -nr