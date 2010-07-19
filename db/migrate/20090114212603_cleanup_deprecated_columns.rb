class CleanupDeprecatedColumns < ActiveRecord::Migration
  def self.up
    remove_column :crates, :context
    remove_column :crates, :question
    remove_column :crates, :answer

    remove_column :users, :current_level
    remove_column :users, :primary_association
    remove_column :users, :secondary_association
    remove_column :users, :tertiary_association

    remove_column :levels, :missions_taken
    remove_column :levels, :missions_created
    remove_column :levels, :armors_donned
    remove_column :levels, :crates_deployed
    remove_column :levels, :lightposts_deployed
    remove_column :levels, :mines_deployed
    remove_column :levels, :portals_deployed
    remove_column :levels, :rockets_fired
    remove_column :levels, :walls_deployed
    remove_column :levels, :st_nicks_attached
    remove_column :levels, :portals_taken
  end

  def self.down
    # one way road, here, but rails cries hard when you muck with columns (so we're stubbing these out for db:migrate:redo)
    add_column :crates, :context, :string
    add_column :crates, :question, :string
    add_column :crates, :answer, :string
  
    add_column :users, :current_level, :integer
    add_column :users, :primary_association, :string
    add_column :users, :secondary_association, :string
    add_column :users, :tertiary_association, :string

    add_column :levels, :missions_taken, :integer
    add_column :levels, :missions_created, :integer
    add_column :levels, :armors_donned, :integer
    add_column :levels, :crates_deployed, :integer
    add_column :levels, :lightposts_deployed, :integer
    add_column :levels, :mines_deployed, :integer
    add_column :levels, :portals_deployed, :integer
    add_column :levels, :rockets_fired, :integer
    add_column :levels, :walls_deployed, :integer
    add_column :levels, :st_nicks_attached, :integer
    add_column :levels, :portals_taken, :integer
  end
end
