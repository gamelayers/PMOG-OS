require File.dirname(__FILE__) + '/lib/better_name_nanny'
ActiveRecord::Base.extend BetterNameNanny
