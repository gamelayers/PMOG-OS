import os
import sys
from lib import yaml
from lib import timeoutsocket
timeoutsocket.setDefaultSocketTimeout(5)

FEEDS_PER_THREAD = 100

SCRIPT_DIR = os.path.join(os.getcwd(),
                              os.path.split(sys.argv[0])[0])
DATABASE_FILE = os.path.join(SCRIPT_DIR, '..', '..', 'config', 'database.yml')

class DBConfig:
    def __init__(self, dbType):
        dbConfig = yaml.load(open(DATABASE_FILE))
        if not dbConfig.get(dbType):
            raise TypeError("No such database type: %s" % dbType)    
        db = dbConfig[dbType]
        self.host = db['host']
        self.db = db['database']
        self.user = db['username'] or ''
        self.pw = db['password'] or ''

DBCONFIG = None
