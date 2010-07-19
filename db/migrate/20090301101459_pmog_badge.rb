class PmogBadge < ActiveRecord::Migration
  def self.up
    group = Group.find_by_name 'PMOG'
    Badge.create( :name => "PMOG", :group_id => group.id, :description => "If you played PMOG: The Passively Multiplayer Online Game, you earned this badge." )
  end

  def self.down
    Badge.find_by_name( "PMOG" ).destroy
  end
end
