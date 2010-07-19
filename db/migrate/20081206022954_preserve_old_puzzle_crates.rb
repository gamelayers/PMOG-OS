class PreserveOldPuzzleCrates < ActiveRecord::Migration
  def self.up
    @all_crates = Crate.find(:all)
    
    @all_crates.each do |crate|
      if(crate.context=="puzzle" && !crate.question.nil?)
        crate.create_crate_upgrade(
        :puzzle_question => crate.question,
        :puzzle_answer => crate.answer,
        :exploding => nil)
      end
    end
  end

  def self.down
  end
end
