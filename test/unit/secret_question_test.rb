require 'test_helper'

class SecretQuestionTest < ActiveSupport::TestCase

  def test_question_creation
    assert_difference SecretQuestion, :count do
      SecretQuestion.create(:question => "What sound does a dog make?")
    end
  end
end
