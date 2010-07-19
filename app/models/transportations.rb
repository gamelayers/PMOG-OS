class Transportation < ActiveRecord::Base
  belongs_to :portal
  belongs_to :user
end
