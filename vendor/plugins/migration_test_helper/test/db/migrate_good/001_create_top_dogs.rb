class CreateTopDogs < ActiveRecord::Migration
  def self.up
    create_table :top_dogs do |t|
      t.column :name, :string
    end
  end

  def self.down
    drop_table :top_dogs
  end
end
