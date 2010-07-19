class UpdateImpedeAndOverclockSettings < ActiveRecord::Migration
  def self.up
    Ability.reset_column_information

    overclock_data = { :name => "Overclock",
      :url_name => 'overclock',
      :value => 5,
      :charges => 5,
      :classpoints => 0,
      :pmog_class_id => nil,
      :icon_image => "/images/shared/icons/overclock-16.png",
      :small_image => "/images/shared/icons/overclock-32.png",
      :medium_image => "/images/shared/icons/overclock-48.png",
      :short_description => "A player who has been overclocked will earn 5 classpoints extra for their next 5 actions.",
      :long_description => "Players with the ability to Overclock others cannot Overclock themselves. Overclock can be used 5 times per day (Pacific Standard Time) by the player who has the ability. Overclock is not class or level-specific, and can only be used by Order players who have earned the Inviting badge by getting 5 other players to join The Nethernet. A player who has been Overclocked may have up to 25 charges stacked on them." }

    impede_data = { :name => "Impede",
      :url_name => 'impede',
      :charges => 5,
      :value => 5,
      :classpoints => 0,
      :pmog_class_id => nil,
      :icon_image => "/images/shared/icons/impede-16.png",
      :small_image => "/images/shared/icons/impede-32.png",
      :medium_image => "/images/shared/icons/impede-48.png",
      :short_description => "A player who has been impeded will earn 5 classpoints less for their next 5 actions.",
      :long_description => "Players with the ability to Impede others cannot Impede themselves. Impede can be used 5 times per day (Pacific Standard Time) by the player who has the ability. Impede is not class or level-specific, and can only be used by players who have earned the Inviting badge by getting 5 other players to join The Nethernet. A player who has been Impeded may have up to 25 charges stacked on them." }


    @overclock = Ability.find(:first, :conditions => {:url_name => 'overclock'})
    @overclock.update_attributes(overclock_data)

    @impede = Ability.find(:first, :conditions => {:url_name => 'impede'})
    @impede.update_attributes(impede_data)
  end

  def self.down
  end
end
