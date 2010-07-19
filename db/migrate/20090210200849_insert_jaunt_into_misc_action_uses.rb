class InsertJauntIntoMiscActionUses < ActiveRecord::Migration
  def self.up
    jaunt_data = { :name => "Jaunt",
      :url_name => 'jaunt',
      :classpoints => 0,
      :short_description => "Jaunt to a random portal" }

    @jaunt = MiscAction.find_by_url_name('jaunt')
    if @jaunt.nil?
      MiscAction.create(jaunt_data)
    else
      @jaunt.update_attributes(jaunt_data)
    end
  end

  def self.down
  end
end
