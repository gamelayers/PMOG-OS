class CreateGambits < ActiveRecord::Migration
  def self.up
    create_table :gambits do |t|
      t.timestamps
      t.timestamp :completed_at
      t.timestamp :deleted_at
      t.integer :payment_id
      t.string :ocid
      t.string :uid
      t.string :amount, :limit => 32
      t.string :time
      t.string :oid
      t.string :title
      t.string :subid1
      t.string :subid2
      t.string :subid3
      t.string :sig, :limit => 16
      t.string :ip, :limit => 16
      t.string :pending, :limit =>10
    end

    add_index :gambits, [:ocid, :created_at, :pending]
  end

  def self.down
    drop_table :gambits
  end
end
