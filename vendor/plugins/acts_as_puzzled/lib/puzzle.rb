class Puzzle < ActiveRecord::Base

  belongs_to :puzzled, :polymorphic => true

  def solve attempt
    attempt && (attempt.strip.chomp.downcase == answer.strip.chomp.downcase)
  end

end
