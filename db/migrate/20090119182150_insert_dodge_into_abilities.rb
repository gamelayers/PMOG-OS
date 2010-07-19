class InsertDodgeIntoAbilities < ActiveRecord::Migration
  def self.up
    @dodge = Ability.find_by_url_name("dodge")

    if(@dodge.nil?)
      Ability.reset_column_information
      Ability.create( :name => "Dodge",
        :url_name => "dodge",
        :level => 3,
        :association_id => PmogClass.find_by_name('Bedouins').id,
        :short_description => "Dodge a mine after seting it off, avoiding all damage.",
        :classpoints => 15)
    end
  end

  def self.down
  end
end
