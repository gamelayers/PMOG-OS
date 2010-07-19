#!/usr/bin/env python

# Written by mage2k from EngineYard
#
# For parsing a slow query log and return the most used queries
#
# USAGE:
#
# top_slow.py slow_query.log -c 10
# top_slow.py slow_query.log -t count

import sys, os, re
import optparse

gt = lambda x, y: x > y
lt = lambda x, y: not gt(x,y)

class InsSortList(list):
    def __init__(self, values=[], key=lambda x: x, max_size=None, reverse=False):
        self.key = key
        self.max_size = max_size
        
        self.cmp = reverse and gt or lt
        
        for v in values:
            self.insert(v)
    
    def insert(self, new):
        for i in xrange(len(self)+1):
            if i == len(self) or self.cmp(self.key(new), self.key(self[i])):
                list.insert(self, i, new)
                break
            
        if self.max_size and len(self) > self.max_size:
            self.pop()

    def __setitem__(self, i, v):
        raise TypeError("Method __setitem__ not supported for InsSortList")
    
    def append(self, v):
        self.insert(v)
    
    def extend(self, l):
        [self.insert(v) for v in l]

usage="%prog [-h] [-t avg|count|total] [-c N] <aggregated slow log>"
parser = optparse.OptionParser(usage=usage)
parser.add_option('-t', '--type', default='avg', help="The type to sort on, one of: avg, count, total.  Default: avg")
parser.add_option('-c', '--count', type='int', default=5, help="The number of results to display.  Default: 5")

if len(sys.argv) == 1:
    sys.argv.append('-h')
    
opts, args = parser.parse_args(sys.argv[1:])

if not os.path.isfile(args[0]):
    parser.error("%s is not a valid file" % args[0])

if opts.type not in ['avg', 'count', 'total']:
    parser.error("%s is not a valid type to sort on." % opts.type)
    
typ = opts.type
count = opts.count

r = re.compile(r'^Count:\s+(\d+)\s+Time=(\d+(?:\.\d+))s\s+\((\d+)s\)')
typ_map = {'count': 0, 'avg': 1, 'total': 2} # #s match captured groups in regex

results = InsSortList(key=lambda t: t[0][typ_map[typ]], max_size=count, reverse=True)
for line in (l.strip() for l in open(args[0])):
    if not line:
        continue
    m = re.match(r, line)
    if m:
        k = tuple([float(v) for v in m.groups()])
        curr = (k, [])
        results.insert(curr)
    if results: # safety check, false if run on a non-aggregate slow query log
        curr[1].append(line)

print 'Top %d by %s:\n' % (count, typ)
for _, lines in results:
    print '\n'.join(lines) + '\n'
