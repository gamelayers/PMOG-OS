class InsertVengeanceIntoAbilities < ActiveRecord::Migration
  def self.up
    vengeance_data = { :name => "Vengeance",
      :url_name => 'vengeance',
      :ping_cost => 20,
      :level => 15,
      :classpoints => 10,
      :association_id => PmogClass.find_by_name("Bedouins"),
      :short_description => "Vengeance returns damage that a destroyer would deal back to them." }

    @vengeance = Ability.find_by_url_name('vengeance')
    if @vengeance.nil?
      Ability.create(vengeance_data)
    else
      @vengeance.update_attributes(vengeance_data)
    end
  end

  def self.down
  end
end
