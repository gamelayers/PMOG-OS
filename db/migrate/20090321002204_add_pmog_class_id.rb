class AddPmogClassId < ActiveRecord::Migration
  def self.up
    add_column :misc_actions, :pmog_class_id, :int

    MiscAction.reset_column_information
    seer = PmogClass.find_by_name('Seers')

    @jaunt = MiscAction.find_by_url_name('jaunt')
    @jaunt.update_attributes(:pmog_class_id => seer.id)
    
    @transportation = MiscAction.find_by_url_name('portal_transportation')
    @transportation.update_attributes(:pmog_class_id => seer.id)

    @grenadiers = PmogClass.find_by_name('Grenadiers')
    @riveters = PmogClass.find_by_name('Riveters')

    @grenadiers.destroy unless @grenadiers.nil?
    @riveters.destroy unless @riveters.nil?
  end

  def self.down
    remove_column :misc_actions, :pmog_class_id
  end
end
