class AddPuzzleSummaryToMissions < ActiveRecord::Migration
  def self.up
    add_column :missions, :puzzle, :boolean, :default => false

    Mission.reset_column_information

    Mission.all do |mission|
      mission.branches.each do |branch|
        unless branch.puzzle.nil?
          mission.puzzle = true
          mission.save
          break
        end
      end
    end

  end

  def self.down
    remove_column :missions, :puzzle
  end
end
