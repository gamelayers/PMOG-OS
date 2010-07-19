#!/bin/bash
# Testing
cd /data/pmog/current
(/usr/bin/ruby /data/pmog/current/test/integration/spider_test_test.rb > "public/system/data/spider-test-`date +%Y-%m-%d-%H-%M`.txt") >> /dev/null 2>&1
(/usr/bin/rake -f /data/pmog/current/Rakefile pmog:coverage) >> /dev/null 2>&1
cp -r doc/coverage/ /data/pmog/current/public/system/data/
