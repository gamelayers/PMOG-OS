class InsertOverlockAndImpedeIntoAbilities < ActiveRecord::Migration
  def self.up
    Ability.reset_column_information

    overclock_data = { :name => "Overclock",
      :url_name => 'overclock',
      :charges => 5,
      :classpoints => 0,
      :pmog_class_id => PmogClass.find_by_name("Benefactors").id,
      :short_description => "Grants another player bonus classpoints as they play." }

    impede_data = { :name => "Impede",
      :url_name => 'impede',
      :charges => 5,
      :classpoints => 0,
      :pmog_class_id => PmogClass.find_by_name("Destroyers").id,
      :short_description => "Slows the classpoint gain of another player." }


    @overclock = Ability.find(:first, :conditions => {:url_name => 'overclock'})
    @overclock.nil? ? Ability.create(overclock_data) : @overclock.update_attributes(overclock_data)

    @impede = Ability.find(:first, :conditions => {:url_name => 'impede'})
    @impede.nil? ? Ability.create(impede_data) : @impede.update_attributes(impede_data)
  end

  def self.down
    @overclock = Ability.find(:first, :conditions => {:url_name => 'overclock'})
    @overclock.destroy unless @overclock.nil?

    @impede = Ability.find(:first, :conditions => {:url_name => 'impede'})
    @impede.destroy unless @impede.nil?
  end
end
