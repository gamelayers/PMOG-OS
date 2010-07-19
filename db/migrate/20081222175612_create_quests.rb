class CreateQuests < ActiveRecord::Migration
  def self.up
    create_table :quests, :id => false do |t|
      t.string :id, :user_id, :limit => 36
      t.string :name, :description
      t.timestamps
    end
  end

  def self.down
    drop_table :quests
  end
end
