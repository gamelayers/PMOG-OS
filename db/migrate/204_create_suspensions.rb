class CreateSuspensions < ActiveRecord::Migration
  def self.up
    create_table :suspensions, :id => false do |t|
      t.string :id, :user_id, :admin_id, :null => false, :limit => 36
      t.text :reason, :limit => 500
      t.timestamps
      t.timestamp :expires_at
    end
  end

  def self.down
    drop_table :suspensions
  end
end
