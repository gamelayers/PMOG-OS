class InsertDisarmIntoAbilities < ActiveRecord::Migration
  def self.up
    # insert/update the disarm entry in :abilities
    disarm_data = Hash[:name => "Dodge and Disarm",
      :url_name => 'disarm',
      :level => 12,
      :ping_cost => 15,
      :association_id => PmogClass.find_by_name('Bedouins').id,
      :short_description => "Stop an attack and pocket the tool used against you.",
      :classpoints => 15]
    
    Ability.reset_column_information
    @disarm = Ability.find_by_url_name('disarm')
    if(@disarm.nil?)
      Ability.create(disarm_data)
    else
      @disarm.update_attributes(disarm_data)
    end
  end

  def self.down
  end
end
