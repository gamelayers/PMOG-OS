require 'test_helper'

class UserSecretTest < ActiveSupport::TestCase
  fixtures :users, :secret_questions

  def test_user_secret_create
    user = users(:marc)
    secret = secret_questions(:color)

    assert_nil user.user_secret

    assert_difference UserSecret, :count do
      user.create_user_secret(:secret_question_id => secret.id, :answer => "red")
    end

    assert_equal "What is your favorite color?", user.user_secret.secret_question.question
  end

  def test_user_secret_answer
    user = users(:marc)
    secret = secret_questions(:videogame)

    user.create_user_secret(:secret_question_id => secret.id, :answer => "Gears of War 2")

    assert_equal false, user.user_secret.answer?("Teenage Mutant Ninja Turtles")

    assert_equal true, user.user_secret.answer?("Gears of War 2")

    assert_equal true, user.user_secret.answer?("gears of war 2")
  end
end
