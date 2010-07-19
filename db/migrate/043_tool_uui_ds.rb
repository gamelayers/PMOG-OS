class ToolUuiDs < ActiveRecord::Migration
  def self.up
    drop_table :tools
    
    create_table :tools, :id => false do |t|
      t.column :id, :string, :limit => 36
      t.column :name, :string, :null => false
      t.column :description, :text, :null => false
      t.column :cost, :int, :null => false, :default => 0
      t.column :character, :string, :null => false
    end

    add_index :tools, :id
    add_index :tools, :name
    add_index :tools, :character
    
    Tool.create( :name => 'crates', :description => 'Crates allow the safe storage of items across the web, and also provide for the protection of tools.', :cost => 40, :character => 'hoarder')
    Tool.create( :name => 'lightposts', :description => 'Lightposts hold quests together, illuminating a path through the web curated by a pathmaking person who came before.', :cost => 40, :character => 'pathmaker')
    Tool.create( :name => 'mines', :description => 'Mines catch users traveling by and self-destruct to create havok. When mines explode, they damage any tools on the same square, and the user who triggers them takes damage as well.', :cost => 40, :character => 'destroyer')
    Tool.create( :name => 'portals', :description => 'Portals are a means of traveling from point to point online, guided by the player who puts them down. A moment of adventure, leading you to an item, perhaps, or a mine. Depending! Who do you trust?', :cost => 40, :character => 'seer')
  end

  def self.down
    drop_table :tools

    create_table :tools do |t|
      t.column :name, :string, :null => false
      t.column :description, :text, :null => false
      t.column :cost, :int, :null => false, :default => 0
      t.column :character, :string, :null => false
    end
    
    add_index :tools, :name
    add_index :tools, :character
    
    puts "[WARNING] Remember to alter tool.rb and remove the before_filter that creates the UUID primary keys!"
  end
end