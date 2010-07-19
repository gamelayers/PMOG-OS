#!/bin/bash
# Stats
cd /data/pmog/current
(/usr/bin/pl_analyze log/production.log > "public/system/data/pl_analyze-`date +%Y-%m-%d-%H-%M`.txt") >> /dev/null 2>&1
(cat log/production.log | grep Completed | awk '{ print "[" $8 "] - " $0 }' | sort -nr --key=1.1 | head > "public/system/data/completed-total-`date +%Y-%m-%d-%H-%M`.txt") >> /dev/null 2>&1
(cat log/production.log | grep Completed | awk '{ print "[" $13 "] - " $0 }' | sort -nr --key=1.1 | head > "public/system/data/completed-rendering-`date +%Y-%m-%d-%H-%M`.txt") >> /dev/null 2>&1
(ruby -nae 'data = $_.match(/([0-9]+) queries/); puts("[" + sprintf("%03d",data[1]) + "] - " + $_) if /Completed/ and data' log/production.log | sort -nr --key=1.1 | head > "public/system/data/completed-database-`date +%Y-%m-%d-%H-%M`.txt") >> /dev/null 2>&1
(cat log/production.log | grep "(0 reqs\/sec)" | awk '{print "[" $8 "] - " $0 }' | sort -nr --key=1.1 | head > "public/system/data/zero_requests-`date +%Y-%m-%d-%H-%M`.txt") >> /dev/null 2>&1

# rcov
(/usr/bin/rake -f /data/pmog/current/Rakefile pmog:coverage) >> /dev/null 2>&1
cp -r doc/coverage/ /data/pmog/current/public/system/data/

# doc
(cd /data/pmog/current; /usr/bin/rake -f /data/pmog/current/Rakefile doc:reapp)  >> /dev/null 2>&1
cp -r doc/app/ /data/pmog/current/public/system/data/

#(./script/performance/railsbench.sh > "public/system/data/railsbench-`date +%Y-%m-%d-%H-%M`.txt") >> /dev/null 2>&1
#./script/performance/httperf.sh >> /dev/null 2>&1

# Delete any old log files
/usr/bin/find /data/pmog/current/public/system/data/*.txt -mtime +30 -exec rm {} \;