class Gambit < ActiveRecord::Base
  has_one :payment, :as => :item
  GAMBIT = 'gambit'
end
