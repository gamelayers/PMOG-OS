module RailsJitsu
  class User < ActiveRecord::Base
    has_many :subscriptions
    
    attr_accessor :email
  end
end