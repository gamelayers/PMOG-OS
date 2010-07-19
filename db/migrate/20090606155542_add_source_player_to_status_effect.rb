class AddSourcePlayerToStatusEffect < ActiveRecord::Migration
  def self.up
    add_column :status_effects, :source_id, :string, :limit => 36
  end

  def self.down
    remove_column :status_effects, :source_id
  end
end
