class SoulMark < ActiveRecord::Base
  belongs_to :player, :class_name => "User"
  belongs_to :admin, :class_name => "User"

end
