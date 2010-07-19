class CreateAbilityStatuses < ActiveRecord::Migration
  def self.up
    create_table :ability_statuses, :id => false, :force => true  do |t|
      t.string      :id,          :limit => 36,     :null => false
      t.string      :user_id,     :limit => 36,     :null => false
      t.boolean     :dodge,                                           :default => true
      t.boolean     :disarm,                                          :default => true
      t.boolean     :vengeance,                                       :default => true
      t.boolean     :armor_equipped,                                  :default => false
      t.integer     :armor_charges,                                   :default => 0
      t.timestamps
    end
    execute( "ALTER TABLE ability_statuses ADD PRIMARY KEY(id)")
    add_index :ability_statuses, :user_id

    AbilityStatus.reset_column_information
    User.all do |user|
      AbilityStatus.create(:user_id => user.id) if AbilityStatus.find_by_user_id(user.id).nil?
    end
  end

  def self.down
    drop_table :ability_statuses
  end
end
