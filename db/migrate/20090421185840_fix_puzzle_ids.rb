class FixPuzzleIds < ActiveRecord::Migration
  def self.up
    @puzzles = Puzzle.find(:all)

    rename_table :puzzles, :old_puzzles

    create_table :puzzles do |t|
      t.string      :puzzled_id,          :limit => 36,     :null => false
      t.string      :puzzled_type,                          :null => false
      t.string      :question
      t.string      :answer
      t.timestamps
    end

    @puzzles.each do |p|
      Puzzle.create(:puzzled_id => p.puzzled_id, :puzzled_type => p.puzzled_type, :question => p.question, :answer => p.answer)
    end

    drop_table :old_puzzles
  end

  def self.down
    # there is no benefit to going back from this one; this is JUST fixing a bug
  end
end
