class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :actions, :id => false do |t|
      t.string :id, :limit => 36
      t.string :name
      t.string :context
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :actions
  end
end
