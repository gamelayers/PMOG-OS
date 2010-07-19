class Processor < ActiveRecord::Base
  def self.get_name(name)
    name += "_#{RAILS_ENV}" if !IsProduction
    return name
  end
end
