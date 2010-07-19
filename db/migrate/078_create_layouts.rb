class CreateLayouts < ActiveRecord::Migration
  def self.up
    create_table :layouts do |t|
      t.string :name, :default => "order"
    end

    Layout.create :name => "order"
  end

  def self.down
    drop_table :layouts
  end
end
