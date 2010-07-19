class UpdateBuddiesUsersForContacts < ActiveRecord::Migration
  def self.up
    # Updating the buddies_users table for the new Contacts system.
    # - find all rivals and delete the acquaintance record
    # - repeat for allies
    types = ['ally', 'rival']
    types.each do |type|
      buddies = Buddy.find_by_sql("SELECT user_id, buddy_id FROM buddies_users WHERE type = '#{type}'")
      buddies.each do |b|
        Buddy.execute("DELETE FROM buddies_users WHERE user_id = '#{b.user_id}' AND type = 'acquaintance'")
        Buddy.execute("DELETE FROM buddies_users WHERE user_id = '#{b.buddy_id}' AND type = 'acquaintance'")
      end
    end
  end

  def self.down
    # There's no real reason to revert this table, so let's not - duncan 01/03/09
  end
end
