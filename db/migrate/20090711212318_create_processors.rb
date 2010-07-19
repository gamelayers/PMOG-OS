class CreateProcessors < ActiveRecord::Migration
  def self.up
    create_table :processors do |t|
      t.timestamps
      t.string :name, :limit => 128
      t.string :campaign_key, :limit => 128
      t.string :secret_key, :limit => 128 # hmmmm
    end
  end

  def self.down
    drop_table :processors
  end
end
