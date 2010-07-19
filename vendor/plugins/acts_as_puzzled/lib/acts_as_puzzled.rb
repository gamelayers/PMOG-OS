# ActsAsPuzzled
module ActsAsPuzzled

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def acts_as_puzzled
      has_one :puzzle, :as => :puzzled
      include ActsAsPuzzled::InstanceMethods
      extend ActsAsPuzzled::SingletonMethods
    end
  end

  # This module contains class methods
  module SingletonMethods
  end

  # This module contains instance methods
  module InstanceMethods
    def set_puzzle question, answer
      puzzle_data = { :puzzled_id => id, :puzzled_type => self.class.name, :question => question, :answer => answer }
      # create or update invisibly depending on if a record already exists
      puzzle = Puzzle.find(:first, :conditions => [ "puzzled_id = ? AND puzzled_type = ?", id, self.class.name ])
      puzzle.nil? ? Puzzle.create(puzzle_data) : puzzle.update_attributes(puzzle_data)
    end

    def clone_puzzle host
      puzzle_data = { :puzzled_id => id, :puzzled_type => self.class.name, :question => host.puzzle.question.to_s, :answer => host.puzzle.answer.to_s }
      # create or update invisibly depending on if a record already exists
      puzzle = Puzzle.find(:first, :conditions => [ "puzzled_id = ? AND puzzled_type = ?", id, self.class.name ])
      puzzle.nil? ? Puzzle.create(puzzle_data) : puzzle.update_attributes(puzzle_data)
    end

    def solve_puzzle answer
      puzzle = Puzzle.find(:first, :conditions => [ "puzzled_id = ? AND puzzled_type = ?", id, self.class.name ])
      puzzle.solve answer # this will raise a nil exception if you don't have a puzzle defined yet
    end
  end

end
