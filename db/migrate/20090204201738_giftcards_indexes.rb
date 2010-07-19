class GiftcardsIndexes < ActiveRecord::Migration
  def self.up
    execute( "ALTER TABLE giftcards ADD PRIMARY KEY(id)")
    add_index :giftcards, :location_id
    add_index :giftcards, :user_id
  end

  def self.down
    execute( "ALTER TABLE giftcards DROP PRIMARY KEY")
    remove_index :giftcards, :location_id
    remove_index :giftcards, :user_id
  end
end
