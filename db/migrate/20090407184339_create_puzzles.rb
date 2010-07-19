class CreatePuzzles < ActiveRecord::Migration
  def self.up
    create_table :puzzles, :id => false, :force => true do |t|
      t.string      :puzzled_id,          :limit => 36,     :null => false
      t.string      :puzzled_type,                          :null => false
      t.string      :question
      t.string      :answer
      t.timestamps
    end
  end

  def self.down
    drop_table :puzzles
  end
end
