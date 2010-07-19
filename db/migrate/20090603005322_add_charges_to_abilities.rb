class AddChargesToAbilities < ActiveRecord::Migration
  def self.up
    add_column :abilities, :charges, :integer
  end

  def self.down
    remove_column :abilities, :charges
  end
end
