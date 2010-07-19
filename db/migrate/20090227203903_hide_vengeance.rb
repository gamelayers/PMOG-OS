class HideVengeance < ActiveRecord::Migration
  def self.up
    @vengeance = Ability.find_by_url_name('vengeance')
    @vengeance.destroy
  end

  def self.down
  end
end
