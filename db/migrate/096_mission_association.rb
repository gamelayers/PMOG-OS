class MissionAssociation < ActiveRecord::Migration
  def self.up
    add_column :missions, :association, :string, :default => nil

    # I was going to replace this with SQL to fix a migration issue with a later model change
    # But I don't think it's a necessary process at this point.
    # Mission.find(:all).each do |m|
    #   unless m.tags.nil? or m.tags.empty?
    #     m.association = m.tags[0].name
    #     m.tag_list = ""
    #     m.save
    #   end
    # end
  end

  def self.down
    remove_column :missions, :association
  end
end
