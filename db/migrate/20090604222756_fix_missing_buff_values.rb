class FixMissingBuffValues < ActiveRecord::Migration
  def self.up
    overclock = Ability.find(:first, :conditions => {:url_name => 'overclock'})
    overclock.update_attributes(:value => 5)

    impede = Ability.find(:first, :conditions => {:url_name => 'impede'})
    impede.update_attributes(:value => 5)

    #AbilityStatus.reset_daily_invite_buffs
  end

  def self.down
    # not reverting; these changes should be made for all versions of checked in code
  end
end
