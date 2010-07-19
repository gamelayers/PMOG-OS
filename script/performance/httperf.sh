#! /bin/sh

# This isn't ideal, we taxing the server by running httperf *and*
# serving the app, but we it's enough to give us an idea of what
# the code can handle. Note that if you add any more tests in here,
# you'll need to alter the parse_httperf_log.rb file too.
#
# parse_httperf_log.rb script from http://nubyonrails.com/articles/peepcode-page-caching-and-httperf

# index
/usr/local/bin/httperf --server localhost --uri / --num-conns 100 >> /data/pmog/current/public/system/data/parse_httperf_log-`date +%Y-%m-%d`.txt
                      
# missions            
/usr/local/bin/httperf --server localhost --uri /missions --num-conns 100 >> /data/pmog/current/public/system/data/parse_httperf_log-`date +%Y-%m-%d`.txt
                      
# npcs                
/usr/local/bin/httperf --server locahost --uri /npcs --num-conns 100 >> /data/pmog/current/public/system/data/parse_httperf_log-`date +%Y-%m-%d`.txt
                      
# bird bots           
/usr/local/bin/httperf --server localhost --uri /bird_bots --num-conns 100 >> /data/pmog/current/public/system/data/parse_httperf_log-`date +%Y-%m-%d`.txt

# beta signup
/usr/local/bin/httperf --server localhost --uri /beta/signup/some-random-key --num-conns 100 >> /data/pmog/current/public/system/data/parse_httperf_log-`date +%Y-%m-%d`.txt

cd /data/pmog/current
ruby script/performance/parse_httperf_log.rb /data/pmog/current/public/system/data/parse_httperf_log-`date +%Y-%m-%d`.txt
mv /data/pmog/current/httperf_log.png /data/pmog/current/public/system/data/parse_httperf_log-`date +%Y-%m-%d`.png