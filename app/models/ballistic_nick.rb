class BallisticNick < ActiveRecord::Base
  belongs_to :perp, :class_name => 'User'
  belongs_to :victim, :class_name => 'User'
end
