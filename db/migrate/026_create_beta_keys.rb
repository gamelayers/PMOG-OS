class CreateBetaKeys < ActiveRecord::Migration
  def self.up
    create_table :beta_keys do |t|
      t.column :key, :string, :limit => 10
      t.column :emailed, :int, :default => 0, :limit => 1
    end
    
    100.times do
      BetaKey.create
    end
  end

  def self.down
    drop_table :beta_keys
  end
end
