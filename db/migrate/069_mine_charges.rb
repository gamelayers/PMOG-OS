class MineCharges < ActiveRecord::Migration
  def self.up
    add_column :mines, :charges, :integer, :default => 0
    add_column :locations, :updated_at, :datetime # need this, potentially for caching
    add_column :users, :motto, :string

    # Update the default Mine charges to 5
    mine = Tool.find_by_name( 'mines' )
    mine.charges = 5
    mine.save

    # Set any previously deployed mines to 5 charges
    Mine.find(:all).each do |mine|
      mine.charges = 5
      mine.save
    end
    
    # Set any mines in your inventory to 5 charges too
    tool = Tool.find_by_name('mines')
    mines = Inventory.find_all_by_tool_id( tool.id )
    mines.each do |mine|
      mine.charges = 5
    end
  end

  def self.down
    remove_column :mines, :charges
    remove_column :locations, :updated_at
    remove_column :users, :motto
  end
end