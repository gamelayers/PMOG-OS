class CreateSecretQuestions < ActiveRecord::Migration
  def self.up
    create_table :secret_questions do |t|
      t.string :question
      t.timestamps
    end

    SecretQuestion.create(:question => "What is your favorite color?")
    SecretQuestion.create(:question => "What is your favorite video game?")
    SecretQuestion.create(:question => "What is your favorite website?")
  end

  def self.down
    drop_table :secret_questions
  end
end
