"Super cheap database layer."
import cfg
from pprint import pprint
import time

import MySQLdb
from lib import uuid
from lib import feedparser

def connection():
    conn = MySQLdb.connect(host=cfg.DBCONFIG.host,
                           user=cfg.DBCONFIG.user, db=cfg.DBCONFIG.db,
                           passwd=cfg.DBCONFIG.pw,
                           use_unicode=1, init_command = 'set names utf8')
    #conn.debug = True
    conn.set_character_set('utf8')    
    return conn
    
class CheapOM:

    def fixDate(self, struct_time):
        "Converts struct_time objects into something MySQLdb can handle."
        if struct_time.__class__ == time.struct_time:
            struct_time = MySQLdb.TimestampFromTicks(time.mktime(struct_time))
        return struct_time

    def executeQuery(self, db, sql, args=None):
        cursor = db.cursor()
        cursor.execute(sql, args)
        yield cursor
        cursor.close()
    executeQuery = classmethod(executeQuery)

    def execute(self, db, sql, args=None):
        cursor = db.cursor()
        cursor.execute(sql, args)
        cursor.close()
    execute = classmethod(execute)

    def each(self, db, cls, sql, args=None):
        """Executes a SQL select and yields each result as an instance of
        the given class."""
        for cursor in self.executeQuery(db, sql, args):
            row = cursor.fetchone()
            while row:
                yield cls(*row)
                row = cursor.fetchone()            
    each = classmethod(each)        

    def all(self, db, cls, sql, args=None):
        """Executes a SQL select and returns the results as instances of
        the given class."""
        for cursor in self.executeQuery(db, sql, args):
            rows = cursor.fetchall()
        return [cls(*row) for row in rows]
    all = classmethod(all)

    def inClause(self, items):
        """A hack to generate an IN clause. Neccessary because MySQLdb
        double-quotes strings in tuples."""
        return "(%s" + (", %s" * (len(items)-1)) + ")"        
    inClause = classmethod(inClause)

class Feed(CheapOM):
    def __init__(self, id=None, url=None, etag=None, lastModified=None,
                 error=None):
        self.id, self.url, self.etag, self.lastModified, self.error = \
                 id, url, etag, lastModified, error

    def save(self, db):
        # Do date conversion
        if self.id: #Already exists in database
            sql = "UPDATE feeds set url=%s, etag=%s, last_modified=%s, error=%s where id=%s"
        else: #New feed
            self.id = uuid.uuid1()
            sql = "INSERT INTO feeds (url, etag, last_modified, error, id) VALUES (%s,%s,%s,%s,%s);"
        
        self.execute(db, sql,
                     (self.url, self.etag, self.fixDate(self.lastModified),
                      self.error, self.id))

    def each(cls, db):
        "Yields each feed in the database."
        for i in CheapOM.each(db, cls, "select id, url, etag, last_modified, error from feeds"):
            yield i
    each = classmethod(each)

    def all(cls, db):
        "Returns a list of feeds."
        return CheapOM.all(db, cls, "select id, url, etag, last_modified, error from feeds")
    all = classmethod(all)

    def refresh(self, db):
        """Parses this feed, possibly updating its URL (moved) or
        error (missing or broken). If there are new entries, puts them
        in the database."""
        print "%s: Refreshing" % self.url
        modified = self.lastModified and self.lastModified.timetuple()
        parsed = feedparser.parse(self.url, etag=self.etag, modified=modified)

        if not parsed.get('status'):
            self.error = parsed.get('bozo_exception') or "Probably a timeout."
            self.save(db)
            db.commit()
            return

        if parsed.status == 304: # Not modified.
            print "%s: Not modified." % self.url
            return

        dirty = False
        if not parsed.entries and parsed.get('bozo_exception'):
            self.error = parsed.get('bozo_exception')
            dirty = True

        # Deal with feeds that are broken or invalid by flagging an error.
        if parsed.status > 400:
            self.error = parsed.status
            dirty = True
            
        if not dirty and self.error: # Clear an error that's been fixed
            self.error = None
            dirty = True

        # Hash the entries found in the feed document by their
        # syndication ID.
        entriesBySyndicationID = {}
        for m in parsed.entries:
            id = Message.extractID(m, parsed)
            entriesBySyndicationID[id] = m

        # Create Message objects for existing messages and index them
        # by ID so we can modify them later.
        existingMessages = Message.eachExisting(db, Message, self.id,
                                                entriesBySyndicationID.keys())
        existingMessagesBySyndicationID = {}
        for existingMessage in existingMessages:
            existingMessagesBySyndicationID[existingMessage.syndicationID] = existingMessage

        # Add brand-new messages to the database, and update existing ones.
        for e in parsed.entries:
            id, title, body, content, mediaType, published, updated = Message.extract(e, parsed)
            if not id:
                return

            message = existingMessagesBySyndicationID.get(id)
            if message:
                if self.fixDate(message.updatedAt) != self.fixDate(updated):
                    # Update an existing message.
                    message.title, message.body, message.content, message.mediaType, message.createdAt, message.updatedAt = title, body, content, mediaType, published, updated
                    message.save(db)
            else:
                # Create a new message.
                print "%s: %s is brand new." % (self.url, id)
                message = Message(self.id, id, title, body, mediaType,
                                  published, updated)
                if body or title:
                    message.save(db)

        # Handle updated ETags and Last-Modified dates
        newETag = parsed.get('etag')
        if newETag and newETag != self.etag:
            self.etag = newETag
            dirty = True           

        newModified = parsed.get('modified')
        if newModified and newModified != self.lastModified:
            self.lastModified = parsed.modified
            dirty = True

        # Deal with feeds that have moved.
        if parsed.status == 301:
            self.url = parsed.href
            dirty = True

        if dirty:
            self.save(db)

        # Delete all messages for this feed that aren't found in the most
        # recent feed document. This takes care of old entries and deleted
        # entries.
        feedEntryIDs = entriesBySyndicationID.keys()
        if feedEntryIDs:
            sql = "DELETE FROM messages where feed_id=%s and syndication_id not in " + \
                  self.inClause(feedEntryIDs)
            args = [self.id] + list(feedEntryIDs)
        else: # An empty feed -- probably gone 404 or something.
            sql = "DELETE from messages where feed_id=%s"
            args = [self.id]
        self.execute(db, sql, args)

        #All this stuff has been happening within a database transaction.
        #We now complete the transaction.
        db.commit()

class Message(CheapOM):

    FIELD_STRING = "feed_id, syndication_id, title, body, media_type, created_at, updated_at, id"

    def __init__(self, feedID=None, syndicationID=None,
                 title=None, body=None, mediaType=None,
                 createdAt=None, updatedAt=None, id=None):
        self.feedID, self.syndicationID, self.title, self.body, \
                     self.mediaType, self.createdAt, self.updatedAt, \
                     self.id = \
                        feedID, syndicationID, title, body, mediaType, \
                        createdAt, updatedAt, id

    def save(self, db):
        if not self.body and not self.title:
            raise TypeError("A message must contain a body and/or title.")
        self.body = self.body or ""
        self.title = self.title or ""

        if self.id: #Already exists in database

            sql = """UPDATE messages set feed_id=%s, syndication_id=%s,
            title=%s, body=%s, media_type=%s, created_at=%s, updated_at=%s
            where id=%s"""
        else: #New feed
            self.id = uuid.uuid1()
            sql = "INSERT INTO messages (" + self.FIELD_STRING + ") VALUES (%s,%s,%s,%s,%s,%s,%s,%s);"
        args = (self.feedID, self.syndicationID, self.title,
                self.body, self.mediaType, self.fixDate(self.createdAt),
                self.fixDate(self.updatedAt), self.id)
        self.execute(db, sql, args)

    def eachExisting(self, db, cls, feedID, syndicationIDs):
        if syndicationIDs:
            sql = "SELECT " + cls.FIELD_STRING + " FROM messages WHERE feed_id=%s and syndication_id in " + self.inClause(syndicationIDs)
            args = [feedID] + list(syndicationIDs)
            for i in CheapOM.each(db, cls, sql, args):
                yield i
    eachExisting = classmethod(eachExisting)

    def extract(cls, parsed, feed):
        """Extracts information about a feed entry from a data structure
        created by the Universal Feed Parser."""
        
        id = cls.extractID(parsed, feed)

        title = parsed.get('title')

        body = mediaType = None
        if parsed.get('content'):
            content = parsed.content[0]
        else:
            content = parsed.get('summary_detail')
        if content:
            body = content['value']
            mediaType = content['type']

        published = parsed.get('published_parsed') or parsed.get('updated_parsed')
        updated = parsed.get('updated_parsed') or published
        return (id, title, body, content, mediaType, published, updated)

    extract = classmethod(extract)


    def extractID(cls, parsed, feed):
        """Tries very hard to extract a unique ID from a feed entry data
        structure created by the Universal Feed Parser."""
        id = parsed.get('id') or parsed.get('href')
        if not id:
            links = parsed.get('links')
        if not id and links:
            # Look for a link tag with rel="self".
            for l in links:
                if l.get('rel') == "self":
                    id = l.get('href')
                    break
        if not id and links:
            # Look for a link tag with rel="alternate", and use it
            # UNLESS there are other entries in the feed that use the
            # same "alternate" link. (See: Alien Loves Predator)            
            for l in links:
                if l.get('rel') == "alternate":
                    id = l.get('href')        
                    break

            if id:
                entriesUsingThisLink = 0
                for entry in feed.entries:
                    entryLinks = entry.get('links')
                    if entryLinks:
                        for l in entryLinks:
                            if l.get('rel') == "alternate" and l.get('href') == id:
                                entriesUsingThisLink += 1
                                if entriesUsingThisLink > 1:
                                    id = None
                                    break
                                break
                    if entriesUsingThisLink > 1:
                        break

        if not id and parsed.get('title'):
            # Use the title, UNLESS there are other entries in the feed that
            # use the same title.
            id = parsed.get('title')
            if id:
                entriesUsingThisTitle = 0
                for entry in feed.entries:
                    entryTitle = entry.get('title')
                    if entryTitle == id:
                        entriesUsingThisTitle += 1
                        if entriesUsingThisTitle > 1:
                            id = None
                            break

        if not id:
            # As a last resort, use the publication date.
            id = parsed.get('published_parsed')
        if not id:
            raise TypeError("Could not find GUID for an entry.")
        return id
    extractID = classmethod(extractID)
