class Payment < ActiveRecord::Base
  belongs_to :item, :polymorphic => true
  belongs_to :user

  AUTH = 1
  CREDIT = 2
  VOID = 3
  REFUND = 4

  def self.credit(user, amount, ip=nil, processor_item=nil)
    amount = amount.to_i

    user.add_bacon(amount) do
      payment = Payment.create!(:user => user, :amount => amount, :action => Payment::CREDIT, :ip => ip, :item => processor_item) # payment log from any source
      processor_item.payment = payment
      processor_item.completed_at = Time.now.utc
      processor_item.save!  # update that we processed this row
    end

  end

  def self.admin_credit(user, amount)
    Payment::credit(user, amount, @remote_ip, current_user.login)
  end
end
