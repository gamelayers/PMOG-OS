class CreateGiftcards < ActiveRecord::Migration
  def self.up
    create_table :abilities, :id => false, :force => true do |t|
      #GENERIC FIELDS
      t.string :id, :limit => 36
      t.string :name
      t.string :url_name
      t.string :association_id, :limit => 36
      t.integer :level, :limit => 11
      t.string :short_description
      t.string :icon_image
      t.string :small_image
      t.string :medium_image
      t.string :large_image
      t.text :long_description
      t.text :history
      #ABILITY SPECIFIC FIELDS
      t.integer :dp_cost, :limit => 11
      t.integer :ping_cost, :limit => 11
      t.integer :value, :limit => 11, :default => 0
      t.integer :misc, :limit => 11
      t.timestamps
    end

    create_table :ability_uses, :id => false, :force => true do |t|
      t.string    :id,            :limit => 36
      t.string    :ability_id,    :limit => 36
      t.string    :user_id,       :limit => 36
      t.integer   :points,         :limit => 11
      t.timestamps
    end

    create_table :giftcards, :id => false, :force => true do |t|
      t.string    :id,            :limit => 36
      t.string    :location_id,   :limit => 36
      t.string    :user_id,       :limit => 36
      t.timestamps
    end

    Ability.create( :name => "DP Card",
      :url_name => "giftcard",
      :level => 1,
      :association_id => PmogClass.find_by_name('Benefactors').id,
      :short_description => "Leave a note with 10dp attached for another player to find.",
      :dp_cost => 10,
      :value => 10)
  end

  def self.down
    drop_table :abilities
    drop_table :ability_uses
    drop_table :giftcards
  end
end
