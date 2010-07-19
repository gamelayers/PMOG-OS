class AddProbabilityToAbilities < ActiveRecord::Migration
  def self.up
    add_column :abilities, :percentage, :integer

    @dodge = Ability.find_by_url_name('dodge')
    @dodge.percentage = 10
    @dodge.level = 5
    @dodge.save
  end

  def self.down
    remove_column :abilities, :percentage
  end
end
