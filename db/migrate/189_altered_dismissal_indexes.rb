class AlteredDismissalIndexes < ActiveRecord::Migration
  def self.up
    remove_index :dismissals, :dismissable_type
    remove_index :dismissals, :dismissable_id
    remove_index :dismissals, :user_id
    execute "CREATE INDEX idx_dismissals_on_id_type_user_id ON dismissals(dismissable_id, dismissable_type, user_id)"
  end

  def self.down
    execute "DROP INDEX idx_dismissals_on_id_type_user_id ON dismissals"
    add_index :dismissals, :dismissable_type
    add_index :dismissals, :dismissable_id
    add_index :dismissals, :user_id
  end
end