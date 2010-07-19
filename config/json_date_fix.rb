# A fix for model dates causing circular reference errors when calling to_json
# One that doesn't seem to work, though, with Rails 2.0
# From http://www.eribium.org/blog/?p=106
#ActiveSupport::JSON::Encoders.define_encoder Time do |time|
#  time.to_s
#end
#ActiveSupport::JSON::Encoders.define_encoder Date do |date|
#   date.to_s
#end
