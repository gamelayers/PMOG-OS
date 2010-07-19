class AddGroupsTable < ActiveRecord::Migration
  def self.up
    create_table :groups, :id => false, :force => true do |t|
      t.column :id,             :string,   :limit => 36
      t.column :name,           :string
      t.column :created_at,     :datetime, :null => false
      t.column :updated_at,     :datetime, :null => false
    end 
  end

  def self.down
    drop_table :groups
  end
end
