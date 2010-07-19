class AddQuestionAnswerToCrates < ActiveRecord::Migration
  def self.up
    add_column :crates, :question, :string
    add_column :crates, :answer, :string
  end

  def self.down
    remove_column :crates, :question
    remove_column :crates, :answer
  end
end
