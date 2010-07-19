class UpdateDodgePingCost < ActiveRecord::Migration
  def self.up
    @dodge = Ability.find_by_url_name('dodge')
    dodge_settings = Hash[:name => "Dodge",
      :url_name => 'dodge',
      :level => 5,
      :ping_cost => 5,
      :classpoints => 15]

    if @dodge.nil?
      Ability.create(dodge_settings)
    else
      @dodge.update_attributes(dodge_settings)
    end
  end

  def self.down
  end
end
