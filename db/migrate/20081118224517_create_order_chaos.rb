class CreateOrderChaos < ActiveRecord::Migration
  def self.up
    create_table :order_chaos do |t|
      t.column :name, :string
      t.column :oc_type, :string
      t.column :points, :string
      t.timestamps
    end
    
    c = OrderChaos.create(:name => 'tag_created', :oc_type => 'order', :points => 1)
    c = OrderChaos.create(:name => 'tag_removed', :oc_type => 'chaos', :points => 1)
    c = OrderChaos.create(:name => 'mission_completion_per_url', :oc_type => 'order', :points => 2)
  end

  def self.down
    drop_table :order_chaos
  end
end
