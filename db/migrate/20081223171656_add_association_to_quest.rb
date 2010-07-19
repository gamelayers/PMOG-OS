class AddAssociationToQuest < ActiveRecord::Migration
  def self.up
    add_column :quests, :association, :string
  end

  def self.down
    remove_column :quests, :association
  end
end
