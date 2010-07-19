class CreateAlphaBetaBadges < ActiveRecord::Migration
  def self.up
    Badge.create( :name => "Alpha", :description => "For players who participated in the original alpha version of PMOG").save
    Badge.create( :name => "Beta", :description => "For players who participated in the beta version of PMOG").save
  end

  def self.down
  end
end
