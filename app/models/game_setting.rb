# Just a container for various game settings that we want to tweak
class GameSetting < ActiveRecord::Base
  acts_as_cached

  validates_uniqueness_of :key
  validates_presence_of :key, :value
  validates_length_of :key, :value, :minimum => 1

  def self.value(key)
    get_cache(key, :ttl => 1.week) do
      find(:first, :conditions => { :key => key }).value
    end
  end
end
