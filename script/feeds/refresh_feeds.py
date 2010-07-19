#!/usr/bin/python
# Performs a round of updates on all the feeds in the database.
import sys
from threading import Thread
from Queue import Queue, Empty

from lib import feedparser
from lib.timeoutsocket import Timeout
from om import Feed, connection
import cfg

class FeedUpdater(Thread):
    "A thread whose job is to pull feeds from the queue and update them."
    def __init__(self, feedQueue, name=None):
        Thread.__init__(self, name=name)
        self.queue = feedQueue

    def run(self):
        db = connection()
        try:
            while True:
                feed = self.queue.get(False)
                try:
                    feed.refresh(db)
                except Timeout:
                    feed.error = "Timed out"
                    feed.save(db)
                    db.commit()
                except Exception, e:
                    feed.error = e
                    feed.save(db)
                    db.commit()
                    raise e # Comment out in production                
        except Empty: # We're done.
            db.close()

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print "Usage: %s [database type, eg. 'development'] [feeds to process]" % sys.argv[0]
        sys.exit()
    
    cfg.DBCONFIG = cfg.DBConfig(sys.argv[1])

    db = connection()
    feeds = Feed.all(db)
    if len(sys.argv) > 2: # Only test the feeds specified on the command line
        # Optimization opportunity here if it turns out to be important.
        commandLineFeeds = sys.argv[1:]
        def feedMatches(f):
            for key in commandLineFeeds:
                if f.id == key or f.url == key:
                    return True
            return False
        feeds = [f for f in feeds if feedMatches(f)]
    db.close()

    # Build and populate a feed queue
    queue = Queue()
    for f in feeds:
        queue.put(f, False)

    # Create an appropriate number of threads and set them loose on the
    # feed queue.
    numThreads = len(feeds) / cfg.FEEDS_PER_THREAD + 1
    threads = []
    for i in range(0, numThreads):
        thread = FeedUpdater(queue, name="Feed updater #%d" % i)
        threads.append(thread)
        thread.start()
    for t in threads:
        t.join()
    print "All done!"
