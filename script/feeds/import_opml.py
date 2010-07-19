#!/usr/bin/python
# Test/utility script that imports all the feeds from an OPML file
# into the 'feeds' table. Does not do dupe check.

import sys
from om import Feed, connection
import cfg 
from lib.BeautifulSoup import BeautifulSoup

if len(sys.argv) != 2:
    print "Usage: %s [database type, eg. 'development']" % sys.argv[0]
    sys.exit()
    
cfg.DBCONFIG = cfg.DBConfig(sys.argv[1])
db = connection()

soup = BeautifulSoup(sys.stdin)
feeds = []
for feed in soup.fetch('outline'):
    syndicateURL = feed.get('xmlurl')
    if syndicateURL:
        Feed(url=syndicateURL).save(db)
db.commit()
db.close

