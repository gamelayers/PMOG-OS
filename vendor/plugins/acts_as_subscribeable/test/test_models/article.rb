module RailsJitsu

  require File.join(File.dirname(__FILE__), '../test_helper')

  class Article < ActiveRecord::Base
    acts_as_subscribeable
  end

end