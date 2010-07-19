class DenormalisingTagsOnMissions < ActiveRecord::Migration
  def self.up
    add_column :missions, :cached_tag_list, :string

    # To populate the cached_tag_list column
    Mission.all do |m|
      m.save(false)
    end
  end

  def self.down
    remove_column :missions, :cached_tag_list
  end
end
