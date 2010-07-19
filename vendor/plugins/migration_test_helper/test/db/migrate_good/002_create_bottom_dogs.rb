class CreateBottomDogs < ActiveRecord::Migration
  def self.up
    create_table :bottom_dogs do |t|
      t.column :name, :string
      t.column :sick, :boolean
    end
  end

  def self.down
    drop_table :bottom_dogs
  end
end
