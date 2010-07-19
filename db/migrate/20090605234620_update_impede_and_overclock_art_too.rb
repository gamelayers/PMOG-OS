class UpdateImpedeAndOverclockArtToo < ActiveRecord::Migration
  def self.up
    overclock_data = { :large_image => "/images/shared/tools/large/overclock.png" }
    impede_data = { :large_image => "/images/shared/tools/large/impede.png" }

    @overclock = Ability.find(:first, :conditions => {:url_name => 'overclock'})
    @overclock.update_attributes(overclock_data)

    @impede = Ability.find(:first, :conditions => {:url_name => 'impede'})
    @impede.update_attributes(impede_data)
  end

  def self.down
  end
end
