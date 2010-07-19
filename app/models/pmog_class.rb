# == Schema Information
# Schema version: 20081220201004
#
# Table name: pmog_classes
#
#  id                :integer(11)   not null, primary key
#  name              :string(255)   
#  short_description :string(255)   
#  small_image       :string(255)   
#  large_image       :string(255)   
#  created_at        :datetime      
#  updated_at        :datetime      
#  long_description  :text          
#  history           :text          
#  medium_image      :string(255)   not null
#  icon_image        :string(255)   not null
#

# Class is a reserved word, so PmogClass represents a player class in PMOG.
class PmogClass < ActiveRecord::Base
  acts_as_cached

  has_many :abilities
  has_many :tools
  has_many :upgrades

  def all_actions
    get_cache("all_actions", :ttl => 1.days) do
      actions = []
      actions << self.abilities unless self.abilities.empty?
      actions << self.tools unless self.tools.empty?
      actions << self.upgrades unless self.upgrades.empty?

      actions
    end
  end

  def expire_all
    expire_cache("all_actions")
  end

end
