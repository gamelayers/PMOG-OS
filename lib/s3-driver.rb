#!/usr/bin/env ruby

#  This software code is made available "AS IS" without warranties of any
#  kind.  You may copy, display, modify and redistribute the software
#  code either by itself or as incorporated into your code; provided that
#  you do not remove any proprietary notices.  Your use of this software
#  code is at your own risk and you waive any claim against Amazon
#  Digital Services, Inc. or its affiliates with respect to your use of
#  this software code. (c) 2006-2007 Amazon Digital Services, Inc. or its
#  affiliates.

require 'S3'
require 'time' # for httpdate
require 'net/http'

AWS_ACCESS_KEY_ID = '<INSERT YOUR AWS ACCESS KEY ID HERE>'
AWS_SECRET_ACCESS_KEY = '<INSERT YOUR AWS SECRET ACCESS KEY HERE>'
# remove these next two lines as well, when you've updated your credentials.
print "update #{$0} with your AWS credentials\n"
exit

# convert the bucket to lowercase for vanity domains
# the bucket name must be lowercase since DNS is case-insensitive
BUCKET_NAME = (AWS_ACCESS_KEY_ID + '-test-bucket').downcase
KEY_NAME = 'test-key'

conn = S3::AWSAuthConnection.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
generator = S3::QueryStringAuthGenerator.new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)

# Check if the bucket exists.  The high availability engineering of 
# Amazon S3 is focused on get, put, list, and delete operations. 
# Because bucket operations work against a centralized, global
# resource space, it is not appropriate to make bucket create or
# delete calls on the high availability code path of your application.
# It is better to create or delete buckets in a separate initialization
# or setup routine that you run less often.
if conn.check_bucket_exists(BUCKET_NAME)
  print "----- bucket already exists! -----\n"
else
  print "----- creating bucket -----\n"
  p conn.create_bucket(BUCKET_NAME).message
  # The above is equivalent to:
  #  p conn.create_located_bucket(BUCKET_NAME, S3::BucketLocation::DEFAULT).message
  # Alternatively to create an EU constrainted bucket:
  #  p conn.create_located_bucket(BUCKET_NAME, S3::BucketLocation::EU).message
end

print "----- bucket location -----\n"
case loc = conn.get_bucket_location(BUCKET_NAME).location
when nil
  print "<error>\n"
when ""
  print "<default>\n"
else
  p loc
end


print "----- listing bucket -----\n"
p conn.list_bucket(BUCKET_NAME).entries.map { |entry| entry.key }

print "----- putting object -----\n"
p conn.put(
  BUCKET_NAME,
  KEY_NAME,
  S3::S3Object.new("this is a test"),
  { 'Content-Type' => 'text/plain' }
).message

print "----- listing bucket -----\n"
p conn.list_bucket(BUCKET_NAME).entries.map { |entry| entry.key }

print "----- query string authentication example -----\n"
print "\nTry this url out in your browser (it will only be valid for 60 seconds).\n\n"
generator.expires_in = 60
url = generator.get(BUCKET_NAME, KEY_NAME)
print url, "\n"
print "\npress enter> "
STDIN.getc

print "\nNow try just the url without the query string arguments.  it should fail.\n\n"
print url.gsub(/\?.*$/, ''), "\n"
print "\npress enter> "
STDIN.getc

print "----- putting new object with metadata and public read acl -----\n"
p conn.put(
  BUCKET_NAME,
  KEY_NAME + '-public',
  S3::S3Object.new("this is a publicly readable test", {'blah' => 'foo'}),
  { 'x-amz-acl' => 'public-read', 'Content-Type' => 'text/plain' }
).message

print "----- anonymous read test ----\n"
print "\nYou should be able to try this in your browser\n\n"
print generator.get(BUCKET_NAME, KEY_NAME + '-public').gsub(/\?.*$/, ''), "\n"
print "\npress enter> "
STDIN.getc

print "----- path style url example -----"
print "\nNon-location-constrained buckets can also be specified as part of the url path.  (This was the original url style supported by S3.)\n"
print "\nTry this url out in your browser (it will only be valid for 60 seconds).\n\n"
generator.calling_format = S3::CallingFormat::PATH
url = generator.get(BUCKET_NAME, KEY_NAME)
print url, "\n"
print "\npress enter> "
STDIN.getc

print "----- getting object's acl -----\n"
p conn.get_acl(BUCKET_NAME, KEY_NAME).object.data

print "----- deleting objects -----\n"
p conn.delete(BUCKET_NAME, KEY_NAME).message
p conn.delete(BUCKET_NAME, KEY_NAME + '-public').message

print "----- listing bucket -----\n"
p conn.list_bucket(BUCKET_NAME).entries.map { |entry| entry.key }

print "----- listing all my buckets -----\n"
p conn.list_all_my_buckets.entries.map { |bucket| bucket.name }

print "----- deleting bucket -----\n"
p conn.delete_bucket(BUCKET_NAME).message

