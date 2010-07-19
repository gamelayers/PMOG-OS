class UserSecret < ActiveRecord::Base
  belongs_to :user
  belongs_to :secret_question

  validates_presence_of :answer, :on => :create, :message => "can't be blank"
  validates_presence_of :secret_question_id, :on => :create, :message => "can't be blank"

  def answer?(value)
    return answer.downcase == value.downcase
  end
end
