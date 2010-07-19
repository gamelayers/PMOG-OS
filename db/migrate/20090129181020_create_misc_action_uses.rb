class CreateMiscActionUses < ActiveRecord::Migration
  def self.up
    create_table :misc_action_uses, :id => false, :force => true do |t|
      t.string    :id,            	:limit => 36
      t.string    :misc_action_id,  :limit => 36
      t.string    :user_id,       	:limit => 36
      t.integer   :points,          :limit => 11
      t.timestamps
    end
  end

  def self.down
    drop_table :misc_action_uses
  end
end
