class InsertBallisticNicksIntoUpgrades < ActiveRecord::Migration
  def self.up
    Upgrade.reset_column_information

    ballistic_nick_data = { :name => "Ballistic St. Nick",
      :url_name => 'ballistic_nick',
      :ping_cost => 20,
      :level => 5,
      :damage => 5,
      :classpoints => 15,
      :pmog_class_id => PmogClass.find_by_name("Vigilantes").id,
      :short_description => "Ballistic St. Nicks immediately destroy a player's armor (or shock them a bit if they don't have any on.)" }

    @ballistic_nick = Upgrade.find_by_url_name('ballistic_nick')
    @ballistic_nick.nil? ? Upgrade.create(ballistic_nick_data) : @ballistic_nick.update_attributes(ballistic_nick_data)
  end

  def self.down
    @ballistic_nick = Upgrade.find_by_url_name('ballistic_nick')
    @ballistic_nick.destroy unless @ballistic_nick.nil?
  end
end
