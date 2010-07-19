class CreateCats < ActiveRecord::Migration
  def self.up
    create_table :cats do |t|
      t.column :lives, :integer
    end
  end

  def self.down
    drop_table :cats
  end
end
