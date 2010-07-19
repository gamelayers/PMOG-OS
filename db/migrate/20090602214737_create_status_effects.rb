class CreateStatusEffects < ActiveRecord::Migration
  def self.up
    create_table :status_effects, :id => false do |t|
      t.string :id, :limit => 36
      t.string :user_id, :limit => 36
      t.string :ability_id, :limit => 36
      t.integer :charges
      t.timestamps
    end
  end

  def self.down
#    drop_table :status_effects
  end
end
