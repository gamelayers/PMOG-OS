class AddPmogClassIdToImpedeAndOverclock < ActiveRecord::Migration
  def self.up
    @overclock = Ability.find(:first, :conditions => {:url_name => 'overclock'})
    @overclock.pmog_class_id = PmogClass.find_by_name("Benefactors").id
    @overclock.save

    @impede = Ability.find(:first, :conditions => {:url_name => 'impede'})
    @impede.pmog_class_id = PmogClass.find_by_name("Destroyers").id
    @impede.save
  end

  def self.down
  end
end
