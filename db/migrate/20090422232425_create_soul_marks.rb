class CreateSoulMarks < ActiveRecord::Migration
  def self.up
    create_table :soul_marks do |t|
      t.string      :player_id,         :limit => 36
      t.string      :admin_id,          :limit => 36
      t.text        :comment
      t.timestamps
    end
    add_index :soul_marks, :player_id

  end

  def self.down
    drop_table :soul_marks
  end
end
