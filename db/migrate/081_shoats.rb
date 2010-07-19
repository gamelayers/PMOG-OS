class Shoats < ActiveRecord::Migration
  def self.up
    PmogClass.create( :name => 'Shoat', :short_description => "Young pigs whose sweet, soft flesh has not yet been hardened by wearing armor, whose clean, hard hooves have not been marred by mine blasts. Ah, youth!", :long_description => "Shoats are free to roam PMOG as they will, associating with Order and Chaos both. Shoats may recline on the green swaths of PMOG space, under the glittering moon, thinking only of the joy of undiscovered portals - never fearing retribution or the unordering of their precious tag stacks. No, those thoughts are reserved for the dark moments of each day, when the Other rises in force against you and you must sacrifice your sweet pink flesh to the fires of battle. O! sweet Shoat, it is the best of times and the worst of times.", :small_image => '/images/shoat.jpg', :large_image => '/images/icons/classes/shoat.jpg' )
  end

  def self.down
    PmogClass.find_by_name('Shoat').destroy
  end
end
