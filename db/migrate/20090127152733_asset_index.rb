class AssetIndex < ActiveRecord::Migration
  def self.up
    remove_index :assets, [:attachable_id, :attachable_type]
    add_index :assets, [:attachable_id, :attachable_type, :created_at]
  end

  def self.down
    remove_index :assets, [:attachable_id, :attachable_type, :created_at]
    add_index :assets, [:attachable_id, :attachable_type]
  end
end
