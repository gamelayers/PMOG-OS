class CreateTakings < ActiveRecord::Migration
  def self.up
    create_table :takings, :id => false do |t|
      t.string :id, :mission_id, :user_id, :null => false, :limit => 36
      t.timestamps
    end
  end

  def self.down
    drop_table :takings
  end
end
